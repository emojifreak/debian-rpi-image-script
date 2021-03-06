#!/bin/bash

apt-get -q -y install mmdebstrap qemu-user-static binfmt-support fdisk gdisk dosfstools systemd-container

MNTROOT=`mktemp -d`
MNTFIRM=`mktemp -d`

#DEVFILE=/dev/mmcblk0
echo "Input the device name of an SD card or a USB MSD"
echo -n "for example, /dev/mmcblk0, /dev/sdc, etc.: "
read DEVFILE
#DEVFILE=/dev/loop2
#rm $IMGFILE
#dd if=/dev/zero of=$IMGFILE count=1 seek=`expr 4096 \* 1024 - 1`
#losetup -P $DEVFILE $IMGFILE
#losetup -l
for i in ${DEVFILE}[0-9] ${DEVFILE}p[0-9] /dev/null; do
  umount -qf $i >/dev/null 2>&1
done
dd of=${DEVFILE} if=/dev/zero bs=1MiB count=256
sync
while [ -b ${DEVFILE}1 -o -b ${DEVFILE}p1 ]; do
  partprobe $DEVFILE
  sleep 1  
done

echo -n "Select partition type (msdos or gpt). USB MSD > 2TB needs gpt: "
read PARTTYPE

echo -n "Swap partition size in GB, 0 means no swap partition: "
read SWAPGB

if [ $PARTTYPE = msdos ]; then
  fdisk $DEVFILE <<EOF
o
n
p
1

+256M
a
t
c
n
p
2

-${SWAPGB}GiB
p
w
EOF
elif [ $PARTTYPE = gpt ]; then
  gdisk $DEVFILE <<EOF
2
n
1

256M
EF00
n
2

-${SWAPGB}GiB
8300
p
w
y
EOF
else
  echo "Unknown partition type!"
  exit 1
fi

while [ ! -b ${DEVFILE}1 -a ! -b ${DEVFILE}p1 ]; do
  partprobe $DEVFILE
  sleep 1
done
if [ -b ${DEVFILE}p1 ]; then
  PARTCHAR=p
elif [ -b ${DEVFILE}1 ]; then
  PARTCHAR=""
else
  echo "Unknown device name for the partition 1!"
  exit 1
fi

if [ "$SWAPGB" -gt 0 ]; then
  if [ $PARTTYPE = msdos ]; then
    fdisk $DEVFILE <<EOF
n
p
3


t
3
82
p
w
EOF
  elif [ $PARTTYPE = gpt ]; then
    gdisk $DEVFILE <<EOF
n
3


8200
p
w
y
EOF
  fi
  while [ ! -b ${DEVFILE}${PARTCHAR}3 ]; do
    partprobe $DEVFILE
    sleep 1
  done
  mkswap -f -L RASPISWAP ${DEVFILE}${PARTCHAR}3
fi
   
echo "(btrfs may not work as initramfs is not well supported on Raspberry Pi OS.)"
echo -n "Filesystem type of the root partition (ext4 or btrfs): "
read FSTYPE
dd of=${DEVFILE}${PARTCHAR}2 if=/dev/zero count=512
eval mkfs.${FSTYPE} -L RASPIROOT ${DEVFILE}${PARTCHAR}2
ROOTPARTUUID=`blkid -s PARTUUID -o value ${DEVFILE}${PARTCHAR}2`

echo -n "Debian Suite (buster, bullseye or sid): "
read MMSUITE
cat <<EOF
Explanation of architectures:
armel for Raspberry Pi Zero, Zero W and 1,
armhf for Raspberry Pi 2,
arm64 for Raspberry Pi 3 and 4.
EOF
#echo -n 'Architecture ("armel", "armhf", "arm64", or "armhf,arm64"): '
echo -n 'Architecture ("armel", "armhf", or "arm64"): '
read MMARCH
echo
echo "As defined at https://www.debian.org/doc/debian-policy/ch-archive.html#s-priorities"
echo -n "select installed package coverage (apt, required, important, or standard): "
read MMVARIANT

RASPIFIRMWARE=wireless-regdb,rpi-eeprom,raspberrypi-bootloader,libraspberrypi-bin,bluez-firmware,firmware-atheros,firmware-brcm80211,firmware-libertas,firmware-misc-nonfree,firmware-realtek,raspberrypi-archive-keyring

KERNELPKG=raspberrypi-kernel
echo "Selected kernel package is $KERNELPKG."

echo
echo -n "Choose network configurator (ifupdown, network-manager, systemd-networkd, none): "
read NETWORK

if [ $NETWORK = ifupdown ]; then
  NETPKG=ifupdown,isc-dhcp-client,crda
elif [ $NETWORK = network-manager ]; then
  NETPKG=network-manager,crda
elif [ $NETWORK = systemd-networkd ]; then
  NETPKG=systemd
else
  NETPKG=iproute2,iw
fi

if [ $FSTYPE = btrfs ]; then
  mount -o ssd,async,lazytime,discard,noatime,autodefrag,nobarrier,commit=3600,compress-force=lzo ${DEVFILE}${PARTCHAR}2 ${MNTROOT}
elif  [ $FSTYPE = ext4 ]; then
  mount -o async,lazytime,discard,noatime,nobarrier,journal_async_commit,commit=3600,delalloc,noauto_da_alloc,data=writeback ${DEVFILE}${PARTCHAR}2 ${MNTROOT}
fi
mmdebstrap --architectures=$MMARCH --variant=$MMVARIANT --components="main contrib non-free" --include=${KERNELPKG},busybox-static,debian-archive-keyring,systemd-sysv,udev,kmod,e2fsprogs,btrfs-progs,locales,tzdata,apt-utils,whiptail,wpasupplicant,${NETPKG},${RASPIFIRMWARE},firmware-linux-free,firmware-misc-nonfree,keyboard-configuration,console-setup,fake-hwclock  "$MMSUITE" ${MNTROOT} - <<EOF
deb http://archive.raspberrypi.org/debian/ buster main
deb http://deb.debian.org/debian $MMSUITE main contrib non-free
EOF

mkfs.vfat -v -F 32 -n RASPIFIRM ${DEVFILE}${PARTCHAR}1
mount -o async,discard,lazytime,noatime ${DEVFILE}${PARTCHAR}1 ${MNTFIRM}
cp -Rp ${MNTROOT}/boot/* ${MNTFIRM}
rm -rf ${MNTROOT}/boot/*
umount ${MNTFIRM}
mount -o async,discard,lazytime,noatime ${DEVFILE}${PARTCHAR}1 ${MNTROOT}/boot

echo -n "Choose hostname: "
read YOURHOSTNAME
echo "$YOURHOSTNAME" >${MNTROOT}/etc/hostname
echo "127.0.1.1	${YOURHOSTNAME}" >> ${MNTROOT}/etc/hosts
if [ ${FSTYPE} = btrfs ]; then
  cat >${MNTROOT}/etc/fstab <<EOF
LABEL=RASPIROOT / ${FSTYPE} rw,async,lazytime,discard,compress-force=lzo 0 1
LABEL=RASPIFIRM /boot vfat rw,async,lazytime,discard 0 2
EOF
else
  cat >${MNTROOT}/etc/fstab <<EOF
LABEL=RASPIROOT / ${FSTYPE} rw,async,lazytime,discard 0 1
LABEL=RASPIFIRM /boot vfat rw,async,lazytime,discard 0 2
EOF
fi
if [ "$SWAPGB" -gt 0 ]; then
  echo 'LABEL=RASPISWAP none swap sw,discard 0 0' >>${MNTROOT}/etc/fstab
fi

if [ $NETWORK != none ]; then 
  echo "IPv4 DHCP is assumed."
  echo -n "Name of the primary network interface (eth0, wlan0): "
  read NETIF

  if [ $NETIF = wlan0 ]; then
    echo "As https://wiki.archlinux.org/index.php/Network_configuration/Wireless#Respecting_the_regulatory_domain"
    echo -n "Choose your wireless regulatory domain (hit Enter if unsuer): "
    read REGDOM
    echo -n "Your Wireless LAN SSID: "
    read SSID
    echo -n "Your Wireless LAN passphrease: "
    read PSK
  fi

  if [ $NETWORK = ifupdown ]; then
    NETCONFIG="Network configurations can be changed by /etc/network/interfaces"
    cat >>${MNTROOT}/etc/network/interfaces <<EOF
auto $NETIF
iface $NETIF inet dhcp
EOF
    if [ "$NETIF" = wlan0 ]; then
      NETCONFIG="${NETCONFIG} and /etc/default/crda"
      cat >>${MNTROOT}/etc/network/interfaces <<EOF
    wpa-ssid $SSID
    wpa-psk $PSK
EOF
      if [ -n "$REGDOM" ]; then
	echo "REGDOMAIN=$REGDOM" >>${MNTROOT}/etc/default/crda
      fi
    fi
    echo "/etc/network/interfaces is"
    cat ${MNTROOT}/etc/network/interfaces
  elif [ $NETWORK = network-manager ]; then
    NETCONFIG="Network configurations can be changed by nmtui"
    if [ "$NETIF" = wlan0 ]; then
      NETCONFIG="${NETCONFIG} and /etc/default/crda"
      #UUID=`uuidgen`
      cat >>"${MNTROOT}/etc/NetworkManager/system-connections/${SSID}.nmconnection" <<EOF
[connection]
id=$SSID
type=wifi
permissions=

[wifi]
mac-address-blacklist=
mode=infrastructure
ssid=$SSID

[wifi-security]
key-mgmt=wpa-psk
psk=$PSK

[ipv4]
dns-search=
method=auto

[ipv6]
addr-gen-mode=stable-privacy
dns-search=
method=auto

[proxy]
EOF
      chmod 600 "${MNTROOT}/etc/NetworkManager/system-connections/${SSID}.nmconnection"
      if [ -n "$REGDOM" ]; then
	echo "REGDOMAIN=$REGDOM" >>${MNTROOT}/etc/default/crda
      fi
    fi
  elif [ $NETWORK = systemd-networkd ]; then
    NETCONFIG="Network configurations can be changed by /etc/systemd/network/${NETIF}.network"
    cat >${MNTROOT}/etc/systemd/network/${NETIF}.network <<EOF
[Match]
Name=${NETIF}

[Network]
DHCP=yes
EOF
    systemd-nspawn -q -D ${MNTROOT} -a systemctl enable systemd-networkd
    if [ $NETIF = wlan0 ]; then
      NETCONFIG="${NETCONFIG} and /etc/wpa_supplicant/wpa_supplicant-wlan0.conf"
      if [ -n "$REGDOM" ]; then
	echo "country=$REGDOM" >${MNTROOT}/etc/wpa_supplicant/wpa_supplicant-wlan0.conf
      fi
      cat >>${MNTROOT}/etc/wpa_supplicant/wpa_supplicant-wlan0.conf <<EOF
network={
  ssid="${SSID}"
  scan_ssid=1
  key_mgmt=WPA-PSK
  psk="${PSK}"
}
EOF
      systemd-nspawn -q -D ${MNTROOT} -a systemctl enable wpa_supplicant@wlan0
    fi
  fi
fi

set -x
#systemd-nspawn -q -D ${MNTROOT} -a pam-auth-update
systemd-nspawn -q -D ${MNTROOT} -a passwd root
systemd-nspawn -q -D ${MNTROOT} -a dpkg-reconfigure tzdata
systemd-nspawn -q -D ${MNTROOT} -a dpkg-reconfigure locales
systemd-nspawn -q -D ${MNTROOT} -a dpkg-reconfigure keyboard-configuration
systemd-nspawn -q -D ${MNTROOT} -a fake-hwclock save


mkdir -p ${MNTROOT}/etc/systemd/sleep.conf.d
cat >${MNTROOT}/etc/systemd/sleep.conf.d/nosleep.conf <<'EOF'
[Sleep]
#AllowSuspend=no
#AllowHibernation=no
#AllowSuspendThenHibernate=no
#AllowHybridSleep=no
EOF



if [ "$MMSUITE" != buster ]; then
  systemd-nspawn -q -D ${MNTROOT} -a apt-get -y --purge --autoremove purge python2.7-minimal
fi
set +x


if [ $NETWORK = network-manager -o $NETWORK = systemd-networkd ]; then
  systemd-nspawn -q -D ${MNTROOT} -a apt-get -y --purge --autoremove purge ifupdown
  rm -f ${MNTROOT}/etc/network/interfaces
fi  

cat >>${MNTROOT}/root/.profile <<EOF
echo "$NETCONFIG"
EOF

cat >>${MNTROOT}/boot/config.txt <<EOF
disable_overscan=1
disable_fw_kms_setup=1
dtparam=audio=on,watchdog=on
EOF

if echo $MMARCH | fgrep -q arm64; then 
  cat >>${MNTROOT}/boot/config.txt <<EOF
hdmi_enable_4kp60=1
dtoverlay=vc4-kms-v3d-pi4
arm_64bit=1
EOF
fi

cat >>${MNTROOT}/boot/cmdline.txt <<EOF
root=PARTUUID=${ROOTPARTUUID} rootfstype=$FSTYPE fsck.repair=yes rootwait
EOF
cat ${MNTROOT}/boot/cmdline.txt


umount ${MNTROOT}/boot
umount ${MNTROOT}
rm -rf ${MNTROOT} ${MNTFIRM}
