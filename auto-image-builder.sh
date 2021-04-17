#!/bin/sh

DISTROS="debian devuan"
ARCHS="arm64 armhf armel"

for DISTRO in $DISTROS; do
  sed -i 's/passwd root/passwd -d root/' $DISTRO-rpi-sd-builder.sh
  sed -i 's/dpkg-reconfigure/dpkg-reconfigure -fnoninteractive/' $DISTRO-rpi-sd-builder.sh
done

for DISTRO in $DISTROS; do
  if [ $DISTRO = debian ]; then
    SUITES="bullseye buster"
  elif  [ $DISTRO = devuan ]; then
    SUITES="chimaera beowulf"
  fi  
  for SUITE in $SUITES; do
    for ARCH in $ARCHS; do
      RAWFILE=/var/tmp/${DISTRO}-${SUITE}-${ARCH}-28GiB-`date +%F`.img
      rm -f $RAWFILE
      qemu-img create -f raw $RAWFILE 28G
      LOOPDEVICE=`losetup -f`
      losetup $LOOPDEVICE $RAWFILE
      (
        echo $LOOPDEVICE
	echo msdos
	echo 1
	echo ext4
	echo $SUITE
	echo $ARCH
	echo standard
	if [ $DISTRO = debian ]; then
	  echo network-manager
	fi
	echo ${DISTRO}-${SUITE}-${ARCH}-`date +%F`
	echo eth0
      ) |
      (
        if [ $DISTRO = debian ]; then
          sh debian-rpi-sd-builder.sh >/dev/null
        elif [ $DISTRO = devuan ]; then
          sh devuan-rpi-sd-builder.sh >/dev/null
	fi
      )
      MNT=`mktemp -d`
      mount ${LOOPDEVICE}p2 $MNT
      mount ${LOOPDEVICE}p1 ${MNT}/boot/firmware
      #systemd-nspawn -D $MNT -a passwd -d root
      cat >>${MNT}/root/.profile <<'EOF'
echo "GUI can be installed by apt-get install task-xfce-desktop"
if ! [ -e $HOME/configured.txt ]; then
  set -ex
  passwd root
  dpkg-reconfigure tzdata
  dpkg-reconfigure locales
  dpkg-reconfigure keyboard-configuration
  set +ex
  data >$HOME/configured.txt
fi
EOF
      systemd-nspawn -q -D $MNT -a apt-get -y -q clean
      e4defrag $MNT >/dev/null 2>&1
      fstrim ${MNT}/boot/firmware 
      fstrim ${MNT}
      umount -qf ${MNT}/boot/firmware
      umount -qf ${MNT}
      losetup -d ${LOOPDEVICE}
      rm -rf ${MNT}
      systemd-run --user --scope --nice=19 -p 'CPUSchedulingPriority=idle' xz -9 $RAWFILE &
    done
  done
done
echo "Waiting xz compression to finish..."
wait
