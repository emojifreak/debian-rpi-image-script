#!/bin/bash

apt-get -q -y install mmdebstrap qemu-user-static binfmt-support
mkdir /mnt /mnt2 2>/dev/null

echo -n "Swap partition size in GB, 0 means no swap partition: "
read SWAPGB

DEVFILE=/dev/mmcblk0
#LOOPFILE=/dev/loop2
#rm $IMGFILE
#dd if=/dev/zero of=$IMGFILE count=1 seek=`expr 4096 \* 1024 - 1`
#losetup -P $DEVFILE $IMGFILE
#losetup -l
umount -qf ${DEVFILE}p1
umount -qf ${DEVFILE}p2
umount -qf ${DEVFILE}p3
umount -qf ${DEVFILE}p4
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
partx $DEVFILE
if [ $SWAPGB -gt 0 ]; then
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
partx $DEVFILE
  mkswap -f -L RASPISWAP ${DEVFILE}p3
fi
   
echo -n "Filesystem type of the root partition (ext4 or btrfs): "
read FSTYPE
dd of=${DEVFILE}p2 if=/dev/zero count=512
eval mkfs.${FSTYPE} -L RASPIROOT ${DEVFILE}p2

echo -n "Installed package coverage (apt, required, important, or standard): "
read MMVARIANT
cat <<EOF
Explanation of architectures:
armel for Raspberry Pi Zero, Zero W and 1,
armhf for Raspberry Pi 2,
arm64 for Raspberry Pi 3 and 4.
32-bit kernel is unsupported on 64-bit ARM CPUs.
EOF
#echo -n 'Architecture ("armel", "armhf", "arm64", or "armhf,arm64"): '
echo -n 'Architecture ("armel", "armhf", or "arm64"): '
read MMDEBARCH
if [ $MMDEBARCH == armeb ]; then
    KERNELPKG=linux-image-rpi
elif [ $MMDEBARCH == armhf ]; then
    KERNELPKG=linux-image-armmp-lpae
else
    KERNELPKG=linux-image-arm64
fi
echo "Selected kernel package is $KERNELPKG."
    
mount -o async,lazytime,discard,noatime ${DEVFILE}p2 /mnt
mmdebstrap --architectures=$MMDEBARCH --variant=$MMVARIANT --components="main contrib non-free" --include=${KERNELPKG},sysvinit-core,eudev,kmod,e2fsprogs,btrfs-progs,locales,tzdata,apt-utils,whiptail,ifupdown,isc-dhcp-client,wpasupplicant,crda,raspi-firmware,firmware-brcm80211,firmware-linux-free,firmware-misc-nonfree,keyboard-configuration,console-setup chimaera /mnt http://deb.devuan.org/merged/

mkfs.vfat -v -F 32 -n RASPIFIRM ${DEVFILE}p1
mount -o async,discard,lazytime,noatime ${DEVFILE}p1 /mnt2
cp -Rp /mnt/boot/firmware/* /mnt2
rm -rf /mnt/boot/firmware/*
umount /mnt2
mount -o async,discard,lazytime,noatime ${DEVFILE}p1 /mnt/boot/firmware

echo -n "Choose hostname: "
read YOURHOSTNAME
echo "$YOURHOSTNAME" >/mnt/etc/hostname
cat >/mnt/etc/fstab <<EOF
LABEL=RASPIROOT / ${FSTYPE} rw,async,lazytime,discard 0 1
LABEL=RASPIFIRM /boot/firmware vfat rw,async,lazytime,discard 0 2
EOF
if [ $SWAPGB -gt 0 ]; then
  echo 'LABEL=RASPISWAP none swap sw,discard 0 0' >>/mnt/etc/fstab
fi

echo "IPv4 DHCP is assumed. Otherwise edit /etc/network/interfaces"
echo -n "Name of the primary network interface (eth0, wlan0, none): "
read NETIF

if [ $NETIF != none ]; then
  cat >>/mnt/etc/network/interfaces <<EOF
auto $NETIF
iface $NETIF inet dhcp
EOF
  if [ $NETIF == wlan0 ]; then
    echo -n "Your Wireless LAN SSID: "
    read SSID
    echo -n "Your Wireless LAN passphrease: "
    read PSK
    cat >>/mnt/etc/network/interfaces <<EOF
    wpa-ssid $SSID
    wpa-psk $PSK
EOF
  fi
  echo "/etc/network/interfaces is"
  cat /mnt/etc/network/interfaces
fi

set -x
#chroot /mnt pam-auth-update
chroot /mnt passwd root
chroot /mnt dpkg-reconfigure tzdata
chroot /mnt dpkg-reconfigure locales
chroot /mnt dpkg-reconfigure keyboard-configuration
#chroot /mnt apt-get -y --purge --autoremove purge python2.7-minimal
sed -i "s|${DEVFILE}p2|LABEL=RASPIROOT|" /mnt/boot/firmware/cmdline.txt

umount /mnt/boot/firmware/
umount /mnt
