#!/bin/sh

# Initial configuration by root
echo "Please read this shell script before running it. Hit Enter to continue: "
read tmpvar

cat >/etc/environment <<EOF
#http_proxy=http://192.168.1.2:3128/
#https_proxy=http://192.168.1.2:3128/
#MOZ_ENABLE_WAYLAND=1
#QT_QPA_PLATFORM=wayland
#GDK_BACKEND=wayland
#XDG_SESSION_TYPE=wayland
#CLUTTER_BACKEND=wayland
#SDL_VIDEODRIVER=wayland
PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/games
SDL_RENDER_DRIVER=opengles2
SDL_VIDEO_GLES2=1
EOF
cat >/etc/apt/apt.conf.d/00myconf <<EOF
APT::Default-Release "bullseye";
APT::Install-Recommends 0;
APT::Get::Purge 1;
APT::Get::Upgrade-Allow-New 1;
EOF
cat >>/etc/apt/sources.list <<EOF
deb http://deb.debian.org/debian sid main contrib non-free
deb-src http://deb.debian.org/debian sid main contrib non-free
deb http://deb.debian.org/debian experimental main contrib non-free
deb-src http://deb.debian.org/debian experimental main contrib non-free
EOF

cat >>/root/.bashrc <<EOF
export LANG=C.UTF-8
export PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:/usr/games
EOF

for d in journald logind networkd user system; do
 mkdir /etc/systemd/${d}.conf.d
done
cat >/etc/systemd/journald.conf.d/storage.conf <<EOF
[Journal]
Storage=volatile
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
kyber-iosched
vhost_net
vhost_iotlb
#snd_bcm2835 enable_hdmi=0 enable_headphones=1 enable_compat_alsa=1
EOF

cat >>/etc/initramfs-tools/modules <<EOF
bfq
kyber-iosched
vhost_net
vhost_iotlb
EOF

cat >/etc/udev/rules.d/60-block-scheduler.rules <<'EOF'
ACTION=="add|change", SUBSYSTEM=="block", KERNEL=="sd[a-z]", ATTR{queue/scheduler}="bfq"
ACTION=="add|change", SUBSYSTEM=="block", KERNEL=="mmcblk[0-9]", ATTR{queue/scheduler}="bfq"
ACTION=="add|change", SUBSYSTEM=="block", KERNEL=="vd[a-z]", ATTR{queue/scheduler}="bfq"
EOF

mkdir /etc/systemd/system/apache2.conf.d
cat >/etc/systemd/system/apache2.conf.d/after.conf
[Unit]
After=network-online.target
Requires=network-online.target
EOF

cat >/etc/systemd/system/mycpupower.service <<EOF
[Unit]
After=modprobe@raspberrypi_cpufreq.service
Requires=modprobe@raspberrypi_cpufreq.service

[Service]
Type=oneshot
ExecStart=/usr/bin/cpupower frequency-set -g performance -d 1.5GHz

[Install]
WantedBy=multi-user.target
EOF
systemctl enable mycpupower.service

echo 'CMA="256M@256M"' >>/etc/default/raspi-firmware
set -e
apt-get update
apt-get -y --purge --autoremove --install-recommends install  tasksel/sid tasksel-data/sid
apt-get -y --purge --autoremove --no-install-recommends install systemd-cron dbus-user-session libnss-systemd libpam-systemd
apt-get -y --purge --autoremove --no-install-recommends install alsa-utils pciutils usbutils bluetooth  bluez bluez-firmware
apt-get -y --purge --autoremove --no-install-recommends install desktop-base xfonts-base
apt-get -y --purge --autoremove --no-install-recommends install postfix mailutils
apt-get -y --purge --autoremove --install-recommends install task-japanese/sid fonts-noto-cjk-extra 
apt-get -y --purge --autoremove --no-install-recommends install popularity-contest qemu-user-static binfmt-support reportbug unattended-upgrades rng-tools5 linux-cpupower debian-keyring apparmor-utils apparmor mmdebstrap gpgv arch-test qemu-system-arm qemu-system-gui qemu-system-data qemu-utils qemu-efi-arm qemu-efi-aarch64 ipxe-qemu seabios eject parted arch-test iptables nftables dnsmasq-base rsync openssh-server xauth bc

echo "PermitRootLogin yes" >>/etc/ssh/sshd_config

apt-get -y --purge --autoremove --no-install-recommends install unzip fontconfig

apt-get -y --purge --autoremove --no-install-recommends install emacs-nox emacs-el emacs-common-non-dfsg
apt-get -y --purge --autoremove --no-install-recommends install  libavcodec-extra libavfilter-extra va-driver-all vdpau-driver-all mesa-vulkan-drivers
apt-get -y --purge --autoremove --no-install-recommends install appmenu-gtk3-module libcanberra-gtk3-module
#apt-get -y --purge --autoremove --install-recommends install tigervnc-standalone-server
#apt-get -y --purge --autoremove --no-install-recommends install uim anthy uim-anthy uim-gtk2.0 uim-gtk3 uim-mozc uim-qt5 uim-xim im-config mozc-utils-gui xfonts-base
apt-get -y --purge --autoremove --no-install-recommends install weston xserver-xorg-core xserver-xorg-input-all pulseaudio pulseaudio-utils pulseaudio-module-bluetooth alsa-ucm-conf xdg-user-dirs-gtk xdg-user-dirs xdg-utils
apt-get -y --purge --autoremove --install-recommends install firefox-esr-l10n-ja mrboom fonts-noto-color-emoji
apt-get -y --purge --autoremove --no-install-recommends install accountsservice
apt-get -y --purge --autoremove --no-install-recommends install network-manager-gnome dconf-gsettings-backend gconf-gsettings-backend network-manager-config-connectivity-debian
#apt-get -y --purge --autoremove --no-install-recommends install task-gnome-desktop/sid task-desktop/sid gdm3  gnome-keyring  gnome-screenshot 	gnome-maps 	gnome-color-manager avahi-daemon 	cups-pk-helper 	gnome-tweaks libproxy1-plugin-gsettings libproxy1-plugin-networkmanager
apt-get -y --purge --autoremove --no-install-recommends install xfce4 xfce4-goodies xfce4-notifyd pavucontrol xiccd task-desktop/sid task-xfce-desktop/sid
#apt-get -y --purge --autoremove --no-install-recommends install kde-full qml-module-qtwayland-compositor qml-module-qtwayland-client-texturesharing task-kde-desktop/sid task-desktop/sid plasma-workspace-wayland dragonplayer plasma-nm sddm-theme-debian-maui
apt-get -y --purge --autoremove --install-recommends install task-japanese-desktop/sid
#apt-get -y --purge --autoremove --install-recommends install ibus-gtk3 ibus-gtk ibus-mozc mozc-utils-gui ibus-anthy ibus-wayland im-config
set +x


if true; then
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
mkdir -p /home/$NONROOTUSER/.config
cat >/home/$NONROOTUSER/.config/weston.ini <<EOF
[core]
idle-time=0
modules=systemd-notify.so
#use-pixman=true
[keyboard]
keymap_layout=jp
[terminal]
font=Noto Sans Mono CJK JP
font-size=16
[shell]
locking=false
EOF
chown -R ${NONROOTUSER}.${NONROOTUSER} /home/$NONROOTUSER/.config
