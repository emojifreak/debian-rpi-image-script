#!/bin/sh

# Initial configuration by root
echo "Please read this shell script before running it. Hit Enter to continue: "
read tmpvar

cat >/etc/environment <<EOF
#http_proxy=http://192.168.1.2:3128/
#https_proxy=http://192.168.1.2:3128/
EOF
cat >/etc/apt/apt.conf.d/00myconf <<EOF
APT::Default-Release "chimaera";
APT::Install-Recommends 0;
APT::Get::Purge 1;
APT::Get::Upgrade-Allow-New 1;
EOF
cat >/etc/apt/sources.list <<EOF
deb http://deb.devuan.org/merged chimaera main contrib non-free
deb-src http://deb.devuan.org/merged chimaera main contrib non-free
deb http://deb.devuan.org/merged ceres main contrib non-free
deb-src http://deb.devuan.org/merged ceres main contrib non-free
EOF

cat >>/root/.bashrc <<EOF
export LANG=C.UTF-8
export PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:/usr/games
EOF

cat >>/etc/modules <<EOF
reset_raspberrypi
raspberrypi_cpufreq
raspberrypi_hwmon
EOF

echo 'CMA="256M@256M"' >>/etc/default/raspi-firmware 
apt-get update
apt-get -y --purge --autoremove --install-recommends install  tasksel/ceres tasksel-data/ceres
apt-get -y --purge --autoremove --no-install-recommends install alsa-utils alsa-ucm-conf pciutils usbutils bluetooth  bluez bluez-firmware
apt-get -y --purge --autoremove --no-install-recommends install desktop-base xfonts-base
apt-get -y --purge --autoremove --no-install-recommends install postfix mailutils
apt-get -y --purge --autoremove --no-install-recommends install popularity-contest qemu-user-static binfmt-support reportbug unattended-upgrades rng-tools5 linux-cpupower debian-keyring apparmor-utils apparmor openssh-server xauth

echo "PermitRootLogin yes" >>/etc/ssh/sshd_config

apt-get -y --purge --autoremove --no-install-recommends install  libavcodec-extra libavfilter-extra va-driver-all vdpau-driver-all 
apt-get -y --purge --autoremove --no-install-recommends install appmenu-gtk3-module libcanberra-gtk3-module
apt-get -y --purge --autoremove --no-install-recommends install xserver-xorg-core xserver-xorg-input-all
apt-get -y --purge --autoremove --install-recommends install weston firefox-esr mrboom fonts-noto-color-emoji
apt-get -y --purge --autoremove --install-recommends install task-xfce-desktop/ceres task-desktop/ceres

rm /etc/resolv.conf
cat >/etc/resolv.conf <<EOF
options edns0
nameserver 192.168.1.2
EOF
chmod a-w /etc/resolv.conf

echo -n "Ordinary login user: "
read NONROOTUSER
adduser $NONROOTUSER
# See https://wiki.debian.org/SystemGroups
for g in cdrom floppy audio video plugdev kvm netdev scanner debci libvirt lp adm fax tty bluetooth pulse-access; do
  if fgrep -q $g /etc/group; then
     adduser $NONROOTUSER $g
  fi
done

mkdir -p /home/$NONROOTUSER/.config
cat >/home/$NONROOTUSER/.config/weston.ini <<EOF
[core]
use-pixman=true
[keyboard]
keymap_layout=jp
[shell]
locking=false
EOF
chown -R ${NONROOTUSER}.${NONROOTUSER} /home/$NONROOTUSER/.config
