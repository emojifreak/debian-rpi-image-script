#!/bin/sh

# Initial configuration by root
echo "Please read this shell script before running it. Hit Enter to continue: "
read tmpvar

cat >/etc/environment <<EOF
http_proxy=http://192.168.1.2:3128/
https_proxy=http://192.168.1.2:3128/
EOF
cat >/etc/apt/apt.conf.d/00myconf <<EOF
APT::Default-Release "bullseye";
APT::Install-Recommends 0;
APT::Get::Purge 1;
APT::Get::Upgrade-Allow-New 1;
EOF
cat >/etc/apt/sources.list <<EOF
deb http://deb.debian.org/debian bullseye main contrib non-free
deb-src http://deb.debian.org/debian bullseye main contrib non-free
deb http://deb.debian.org/debian sid main contrib non-free
deb-src http://deb.debian.org/debian sid main contrib non-free
deb http://deb.debian.org/debian experimental main contrib non-free
deb-src http://deb.debian.org/debian experimental main contrib non-free
EOF

cat >>/root/.bashrc <<EOF
export LANG=C.UTF-8
export PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin
EOF

for d in journald logind networkd user system sleep; do
 mkdir /etc/systemd/${d}.conf.d
done
cat >/etc/systemd/journald.conf.d/storage.conf <<EOF
[Journal]
Storage=persistent
Compress=no
EOF

cat >/etc/systemd/logind.conf.d/linger.conf <<EOF
[Login]
KillUserProcesses=yes
KillExcludeUsers=
EOF

cat >/etc/systemd/networkd.conf.d/meter.conf <<EOF
[Network]
SpeedMeter=yes
SpeedMeterIntervalSec=1sec
EOF

cat >/etc/systemd/system.conf.d/account.conf <<EOF
[Manager]
DefaultCPUAccounting=yes
DefaultIOAccounting=yes
DefaultIPAccounting=yes
DefaultBlockIOAccounting=yes
DefaultMemoryAccounting=yes
DefaultTasksAccounting=yes
EOF

cat >/etc/systemd/user.conf.d/acount.conf <<EOF
[Manager]
DefaultCPUAccounting=yes
DefaultIOAccounting=yes
DefaultIPAccounting=yes
DefaultBlockIOAccounting=yes
DefaultMemoryAccounting=yes
DefaultTasksAccounting=yes
EOF

cat >>/etc/modules <<EOF
bfq
kyber
vhost_net
vhost_iotlb
reset_raspberrypi
raspberrypi_cpufreq
raspberrypi_hwmon
EOF

cat >>/etc/initramfs-tools/modules <<EOF
bfq
kyber
vhost_net
vhost_iotlb
EOF

cat >/etc/udev/rules.d/60-block-scheduler.rules <<'EOF'
ACTION=="add|change", SUBSYSTEM=="block", KERNEL=="sd[a-z]", ATTR{queue/scheduler}="kyber"
ACTION=="add|change", SUBSYSTEM=="block", KERNEL=="mmcblk[0-9]", ATTR{queue/scheduler}="kyber"
EOF

#echo 'CMA="256M@256M"' >>/etc/default/raspi-firmware 

apt-get -y --purge --autoremove --no-install-recommends install systemd-cron dbus-user-session libnss-systemd libpam-systemd
apt-get -y --purge --autoremove --no-install-recommends install alsa-utils pciutils usbutils bluetooth  bluez bluez-firmware
apt-get -y --purge --autoremove --no-install-recommends install desktop-base xfonts-base
apt-get -y --purge --autoremove --no-install-recommends install postfix mailutils
apt-get -y --purge --autoremove --install-recommends install task-japanese
apt-get -y --purge --autoremove --no-install-recommends install popularity-contest qemu-user-static binfmt-support reportbug unattended-upgrades rng-tools5 linux-cpupower debian-keyring apparmor-utils apparmor mmdebstrap gpgv arch-test qemu-system-arm qemu-system-gui qemu-system-data qemu-utils qemu-efi-arm qemu-efi-aarch64 ipxe-qemu seabios sdparm sg3-utils eject parted arch-test iptables nftables dnsmasq-base rsync openssh-server xauth

echo "PermitRootLogin yes" >>/etc/ssh/sshd_config

apt-get -y --purge --autoremove --no-install-recommends install unzip fontconfig

apt-get -y --purge --autoremove --no-install-recommends install emacs-gtk emacs-el emacs-common-non-dfsg
apt-get -y --purge --autoremove --no-install-recommends install  libavcodec-extra libavfilter-extra
apt-get -y --purge --autoremove --no-install-recommends install appmenu-gtk3-module libcanberra-gtk3-module
#apt-get -y --purge --autoremove --install-recommends install tigervnc-standalone-server
#apt-get -y --purge --autoremove --no-install-recommends install uim anthy uim-anthy uim-gtk2.0 uim-gtk3 uim-mozc uim-qt5 uim-xim im-config mozc-utils-gui xfonts-base
apt-get -y --purge --autoremove --no-install-recommends install xserver-xorg-core xserver-xorg-video-fbdev xserver-xorg-input-all pulseaudio udisks2
#ln -s /dev/null /etc/systemd/user/pulseaudio.service



if false; then
  cat >/etc/systemd/system/btrfsscrub.service <<'EOF'
[Service]
Type=oneshot
ExecStart=/bin/btrfs scrub start -B -d /
EOF
  cat >/etc/systemd/system/btrfsscrub.timer <<'EOF'
[Timer]
OnCalendar=*-*-* 05:00:00
#Persistent=true
#AccuracySec=1us

[Install]
WantedBy=timers.target
EOF
  systemctl enable btrfsscrub.timer  
fi

rm /etc/resolv.conf
cat >/etc/resolv.conf <<EOF
options edns0
nameserver 192.168.1.2
EOF
chmod a-w /etc/resolv.conf

apt-get -y --purge --autoremove purge ifupdown isc-dhcp-client isc-dhcp-common python2.7-minimal


echo -n "Ordinary login user: "
read NONROOTUSER
adduser $NONROOTUSER
# See https://wiki.debian.org/SystemGroups
for g in cdrom floppy audio video plugdev kvm netdev scanner debci libvirt lp adm systemd-journal fax tty bluetooth pulse-access; do
  if fgrep -q $g /etc/group; then
     adduser $NONROOTUSER $g
  fi
done
