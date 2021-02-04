#!/bin/bash

apt-get -q -y install mmdebstrap qemu-user-static binfmt-support fdisk gdisk dosfstools

if ! dpkg-query -W | fgrep -q devuan-keyring; then
  set -x
  apt-get --no-install-recommends install wget
  wget -P /tmp https://pkgmaster.devuan.org/devuan/pool/main/d/devuan-keyring/devuan-keyring_2017.10.03_all.deb
  dpkg -i /tmp/devuan-keyring_2017.10.03_all.deb
  set +x
fi

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
   
echo -n "Filesystem type of the root partition (ext4 or btrfs): "
read FSTYPE
dd of=${DEVFILE}${PARTCHAR}2 if=/dev/zero count=512
eval mkfs.${FSTYPE} -L RASPIROOT ${DEVFILE}${PARTCHAR}2

echo -n "Devuan Suite (beowulf, chimaera or ceres): "
read MMSUITE
cat <<EOF
Explanation of architectures:
armel for Raspberry Pi Zero, Zero W and 1,
armhf for Raspberry Pi 2,
arm64 for Raspberry Pi 3 and 4.
32-bit kernel is unsupported on 64-bit ARM CPUs.
EOF
echo -n 'Architecture ("armel", "armhf", "arm64", or "armhf,arm64"): '
#echo -n 'Architecture ("armel", "armhf", or "arm64"): '
read MMARCH
echo
echo "As defined at https://www.debian.org/doc/debian-policy/ch-archive.html#s-priorities"
echo -n "select installed package coverage (apt, required, important, or standard): "
read MMVARIANT

if [ "$MMSUITE" = beowulf ]; then
  if echo "$MMARCH" | grep -q arm64; then
    RASPIFIRMWARE=raspi-firmware/beowulf-backports,firmware-brcm80211/beowulf-backports,wireless-regdb/beowulf-backports
  else  
    RASPIFIRMWARE=raspi3-firmware,firmware-brcm80211,wireless-regdb
  fi
  else
  RASPIFIRMWARE=raspi-firmware,firmware-brcm80211,wireless-regdb
fi

if [ "$MMARCH" = armel ]; then
  KERNELPKG=linux-image-rpi
elif [ "$MMARCH" = armhf ]; then
  KERNELPKG=linux-image-armmp-lpae
else
  if [ "$MMSUITE" = beowulf ]; then
    KERNELPKG=linux-image-arm64/beowulf-backports
  else
    KERNELPKG=linux-image-arm64
  fi
fi
echo "Selected kernel package is $KERNELPKG."

if [ $FSTYPE = btrfs ]; then
  mount -o ssd,async,lazytime,discard,noatime,autodefrag,nobarrier,commit=3600,compress-force=lzo ${DEVFILE}${PARTCHAR}2 ${MNTROOT}
elif  [ $FSTYPE = ext4 ]; then
  mount -o async,lazytime,discard,noatime,nobarrier,commit=3600,delalloc,noauto_da_alloc,data=writeback ${DEVFILE}${PARTCHAR}2 ${MNTROOT}
fi

(
  echo "deb http://deb.devuan.org/merged/ $MMSUITE main non-free contrib"
  if [ "$MMSUITE" = beowulf ]; then
    echo "deb http://deb.devuan.org/merged/ beowulf-updates main contrib non-free"
    echo "deb http://deb.devuan.org/merged/ beowulf-security main contrib non-free"
    if echo "$MMARCH" | grep -q arm64; then
      echo "deb http://deb.devuan.org/merged/ beowulf-backports main contrib non-free"
    fi
  fi
) | (
  set -x
  if [ "$MMSUITE" = beowulf ] && echo "$MMARCH" | grep -q arm64; then
    mmdebstrap '--aptopt=APT::Default-Release "beowulf"' --architectures=$MMARCH --variant=$MMVARIANT --components="main contrib non-free" --include=${KERNELPKG},devuan-keyring,sntp,sysvinit-core,eudev,kmod,e2fsprogs,btrfs-progs,locales,tzdata,apt-utils,whiptail,wpasupplicant,ifupdown,isc-dhcp-client,${RASPIFIRMWARE},firmware-linux-free,firmware-misc-nonfree,keyboard-configuration,console-setup,fake-hwclock,crda  "$MMSUITE" $MNTROOT -
  else
    mmdebstrap --architectures=$MMARCH --variant=$MMVARIANT --components="main contrib non-free" --include=${KERNELPKG},devuan-keyring,sntp,sysvinit-core,eudev,kmod,e2fsprogs,btrfs-progs,locales,tzdata,apt-utils,whiptail,wpasupplicant,ifupdown,isc-dhcp-client,${RASPIFIRMWARE},firmware-linux-free,firmware-misc-nonfree,keyboard-configuration,console-setup,fake-hwclock,crda  "$MMSUITE" $MNTROOT -
  fi
)

mkfs.vfat -v -F 32 -n RASPIFIRM ${DEVFILE}${PARTCHAR}1
mount -o async,discard,lazytime,noatime ${DEVFILE}${PARTCHAR}1 ${MNTFIRM}
cp -Rp ${MNTROOT}/boot/firmware/* ${MNTFIRM}
rm -rf ${MNTROOT}/boot/firmware/*
umount ${MNTFIRM}
mount -o async,discard,lazytime,noatime ${DEVFILE}${PARTCHAR}1 ${MNTROOT}/boot/firmware

echo -n "Choose hostname: "
read YOURHOSTNAME
echo "$YOURHOSTNAME" >${MNTROOT}/etc/hostname
if [ ${FSTYPE} = btrfs ]; then
  cat >${MNTROOT}/etc/fstab <<EOF
LABEL=RASPIROOT / ${FSTYPE} rw,async,lazytime,discard,compress-force=lzo 0 1
LABEL=RASPIFIRM /boot/firmware vfat rw,async,lazytime,discard 0 2
EOF
else
  cat >${MNTROOT}/etc/fstab <<EOF
LABEL=RASPIROOT / ${FSTYPE} rw,async,lazytime,discard 0 1
LABEL=RASPIFIRM /boot/firmware vfat rw,async,lazytime,discard 0 2
EOF
fi
if [ "$SWAPGB" -gt 0 ]; then
  echo 'LABEL=RASPISWAP none swap sw,discard 0 0' >>${MNTROOT}/etc/fstab
fi

echo "IPv4 DHCP is assumed. Otherwise edit /etc/network/interfaces"
echo -n "Name of the primary network interface (eth0, wlan0, none): "
read NETIF

if [ "$NETIF" != none ]; then
  cat >>${MNTROOT}/etc/network/interfaces <<EOF
auto $NETIF
iface $NETIF inet dhcp
EOF
  if [ "$NETIF" = wlan0 ]; then
    echo -n "Your Wireless LAN SSID: "
    read SSID
    echo -n "Your Wireless LAN passphrease: "
    read PSK
    cat >>${MNTROOT}/etc/network/interfaces <<EOF
    wpa-ssid $SSID
    wpa-psk $PSK
EOF
  fi
  echo "/etc/network/interfaces is"
  cat ${MNTROOT}/etc/network/interfaces
fi

set -x
#chroot ${MNTROOT} pam-auth-update
chroot ${MNTROOT} passwd root
chroot ${MNTROOT} dpkg-reconfigure tzdata
chroot ${MNTROOT} dpkg-reconfigure locales
chroot ${MNTROOT} dpkg-reconfigure keyboard-configuration
chroot ${MNTROOT} fake-hwclock save

echo "rootfstype=$FSTYPE" >${MNTROOT}/etc/default/raspi-extra-cmdline
echo 'disable_fw_kms_setup=1' >>${MNTROOT}/etc/default/raspi-firmware-custom
echo 'disable_overscan=1' >>${MNTROOT}/etc/default/raspi-firmware-custom
echo 'ROOTPART=LABEL=RASPIROOT' >>${MNTROOT}/etc/default/raspi-firmware
if echo $MMARCH | fgrep -q arm64; then
  echo 'KERNEL_ARCH="arm64"' >>${MNTROOT}/etc/default/raspi-firmware
  echo 'hdmi_enable_4kp60=1' >>${MNTROOT}/etc/default/raspi-firmware-custom
  echo "rootfstype=$FSTYPE module_blacklist=vc4" >${MNTROOT}/etc/default/raspi-extra-cmdline
fi

cat >>${MNTROOT}/etc/initramfs-tools/modules <<EOF
reset_raspberrypi
raspberrypi_cpufreq
raspberrypi_hwmon
EOF

if [ "$SWAPGB" -gt 0 ]; then
  echo 'RESUME="LABEL=RASPISWAP"' >${MNTROOT}/etc/initramfs-tools/conf.d/resume
else
  echo 'RESUME="none"' >${MNTROOT}/etc/initramfs-tools/conf.d/resume
fi

if [ "$MMSUITE" != beowulf ]; then
  chroot ${MNTROOT} apt-get -y --purge --autoremove purge python2.7-minimal
fi

set +x

if [ "$MMSUITE" = beowulf ] && echo "$MMARCH" | grep -q arm64; then
  mv ${MNTROOT}/etc/apt/apt.conf.d/99mmdebstrap ${MNTROOT}/etc/apt/apt.conf
  cat > ${MNTROOT}/etc/apt/sources.list <<EOF
deb http://deb.devuan.org/merged/ $MMSUITE main non-free contrib
deb http://deb.devuan.org/merged/ beowulf-updates main contrib non-free
deb http://deb.devuan.org/merged/ beowulf-security main contrib non-free
deb http://deb.devuan.org/merged/ beowulf-backports main contrib non-free
EOF
fi

cat >>${MNTROOT}/root/.profile <<'EOF'
echo 'Run "sntp -S pool.ntp.org" for correcting the clock of your Raspberry Pi.'
echo 'You should set your country to /etc/default/crda.'
EOF

if which systemd-nspawn | fgrep -q systemd-nspawn; then
  systemd-nspawn -q -D ${MNTROOT} -a update-initramfs -u -k all
else
  chroot ${MNTROOT} update-initramfs -u -k all
fi

sed -i "s|${DEVFILE}${PARTCHAR}2|LABEL=RASPIROOT|" ${MNTROOT}/boot/firmware/cmdline.txt
if echo "$MMARCH" | fgrep -q arm64; then
  sed -i "s|cma=64M||" ${MNTROOT}/boot/firmware/cmdline.txt
  if ! fgrep -q arm_64bit ${MNTROOT}/boot/firmware/config.txt; then
    echo 'arm_64bit=1 is missing in config.txt, something went wrong!'
  fi
fi


umount ${MNTROOT}/boot/firmware/
umount ${MNTROOT}
rm -rf ${MNTROOT} ${MNTFIRM}
