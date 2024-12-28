#!/bin/sh

# Initial configuration by root
echo "Please read this shell script before running it. Hit Enter to continue: "
read tmpvar

mkdir -p /etc/sysctl.d
cat .>/etc/sysctl.d/local.conf <<'EOF'
kernel.randomize_va_space=0
#kernel.randomize_va_space=3
kernel.latencytop=1
kernel.unprivileged_bpf_disabled=0

vm.mmap_rnd_bits=32
vm.mmap_rnd_bits=18
vm.mmap_rnd_compat_bits=11
vm.mmap_min_addr=32678
vm.swappiness=10
vm.overcommit_memory=1
#vm.unprivileged_userfaultfd = 0

net.core.default_qdisc=noqueue
net.core.fb_tunnels_only_for_init_net = 2
net.core.devconf_inherit_init_net = 1
net.core.bpf_jit_harden = 2

net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_ecn=1
net.ipv4.icmp_errors_use_inbound_ifaddr = 1
net.ipv4.tcp_mtu_probing = 2
net.ipv4.tcp_base_mss=1024
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_fastopen_blackhole_timeout_sec = 0
net.ipv4.conf.default.rp_filter=1
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.log_martians = 0
net.ipv4.conf.all.log_martians = 0
net.ipv4.conf.default.arp_announce = 1
net.ipv4.conf.all.arp_announce = 1
net.ipv4.conf.default.arp_ignore = 2
net.ipv4.conf.all.arp_ignore = 2
net.ipv4.tcp_rfc1337 = 0
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling=1

net.ipv6.flowlabel_reflect = 7
net.ipv6.fib_multipath_hash_policy = 2
net.ipv6.seg6_flowlabel = 1
net.ipv6.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
fs.suid_dumpable = 0
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
fs.protected_fifos = 2
fs.protected_regular = 2
kernel.lock_stat=1
EOF

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
%APT::Default-Release "bullseye";
APT::Install-Recommends 0;
APT::Get::Purge 1;
APT::Get::Upgrade-Allow-New 1;
EOF
#cat >>/etc/apt/sources.list <<EOF
#deb http://deb.debian.org/debian sid main contrib non-free
#deb-src http://deb.debian.org/debian sid main contrib non-free
#deb http://deb.debian.org/debian experimental main contrib non-free
#deb-src http://deb.debian.org/debian experimental main contrib non-free
#EOF

cat >>/root/.bashrc <<EOF
export LANG=C.UTF-8
export PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:/usr/games
EOF

for d in journald logind networkd user system; do
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

cat >/etc/modules <<EOF
reset_raspberrypi
raspberrypi_cpufreq
raspberrypi_hwmon
bfq
kyber-iosched
tcp_bbr
jitterentropy_rng
iproc_rng200
EOF

cat >/etc/initramfs-tools/modules <<EOF
reset_raspberrypi
raspberrypi_cpufreq
raspberrypi_hwmon
bfq
kyber-iosched
tcp_bbr
jitterentropy_rng
iproc_rng200
EOF

cat >/etc/udev/rules.d/60-block-scheduler.rules <<'EOF'
ACTION=="add|change", SUBSYSTEM=="block", KERNEL=="sd[a-z]", ATTR{queue/scheduler}="bfq"
ACTION=="add|change", SUBSYSTEM=="block", KERNEL=="mmcblk[0-9]", ATTR{queue/scheduler}="bfq"
ACTION=="add|change", SUBSYSTEM=="block", KERNEL=="vd[a-z]", ATTR{queue/scheduler}="bfq"
EOF

mkdir /etc/systemd/system/apache2.conf.d
cat >/etc/systemd/system/apache2.conf.d/after.conf <<'EOF'
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
ExecStart=/usr/bin/cpupower frequency-set -g schedutil -d 0.6GHz

[Install]
WantedBy=multi-user.target
EOF
systemctl enable mycpupower.service

echo 'CMA="256M@256M"' >>/etc/default/raspi-firmware
set -e
apt-get update
apt-get -y --purge --autoremove --install-recommends install  tasksel tasksel-data
apt-get -y --purge --autoremove --no-install-recommends install systemd-cron dbus-user-session libnss-systemd libpam-systemd
apt-get -y --purge --autoremove --no-install-recommends install alsa-utils pciutils usbutils bluetooth  bluez bluez-firmware
apt-get -y --purge --autoremove --no-install-recommends install desktop-base xfonts-base
apt-get -y --purge --autoremove --no-install-recommends install postfix mailutils
apt-get -y --purge --autoremove --install-recommends install task-japanese fonts-noto-cjk-extra 
apt-get -y --purge --autoremove --no-install-recommends install popularity-contest qemu-user-static binfmt-support reportbug unattended-upgrades rng-tools5 linux-cpupower debian-keyring apparmor-utils apparmor mmdebstrap gpgv arch-test eject parted iptables nftables openssh-server xauth bc #  dnsmasq-base rsync qemu-system-arm qemu-system-gui qemu-system-data qemu-utils qemu-efi-arm qemu-efi-aarch64 ipxe-qemu seabios 

mkdir /etc/ssh/sshd_config.d
cat >/etc/ssh/sshd_config.d/nopassword.conf <<EOF
PasswordAuthentication no
ChallengeResponseAuthentication no
KbdInteractiveAuthentication no
UsePAM yes
EOF

cat /etc/systemd/system/rngd.service <<'EOF'
[Unit]
Description=Start entropy gathering daemon (rngd)
Documentation=man:rngd(8)
DefaultDependencies=no
#After=local-fs.target
After=systemd-udevd.service local-fs.target
Requires=systemd-udevd.service
Wants=systemd-random-seed.service
AssertPathExists=/dev/hwrng
AssertPathIsReadWrite=/dev/random

[Service]
ExecStart=/usr/sbin/rngd -f --rng-device=/dev/hwrng

[Install]
WantedBy=sysinit.target
EOF

apt-get -y --purge --autoremove --no-install-recommends install unzip fontconfig
apt-get -y --purge --autoremove --no-install-recommends install emacs-nox emacs-el emacs-common-non-dfsg

apt-get -y --purge --autoremove --no-install-recommends install  libavcodec-extra libavfilter-extra va-driver-all vdpau-driver-all mesa-vulkan-drivers
#apt-get -y --purge --autoremove --no-install-recommends install appmenu-gtk3-module libcanberra-gtk3-module
#apt-get -y --purge --autoremove --install-recommends install tigervnc-standalone-server
#apt-get -y --purge --autoremove --no-install-recommends install uim anthy uim-anthy uim-gtk2.0 uim-gtk3 uim-mozc uim-qt5 uim-xim im-config mozc-utils-gui xfonts-base
#apt-get -y --purge --autoremove --no-install-recommends install weston xserver-xorg-core xserver-xorg-input-all pulseaudio pulseaudio-utils pulseaudio-module-bluetooth alsa-ucm-conf xdg-user-dirs-gtk xdg-user-dirs xdg-utils
#apt-get -y --purge --autoremove --install-recommends install firefox-esr-l10n-ja mrboom fonts-noto-color-emoji
#apt-get -y --purge --autoremove --no-install-recommends install accountsservice
#apt-get -y --purge --autoremove --no-install-recommends install network-manager-gnome dconf-gsettings-backend gconf-gsettings-backend network-manager-config-connectivity-debian
#apt-get -y --purge --autoremove --no-install-recommends install task-gnome-desktop/sid task-desktop/sid gdm3  gnome-keyring  gnome-screenshot 	gnome-maps 	gnome-color-manager avahi-daemon 	cups-pk-helper 	gnome-tweaks libproxy1-plugin-gsettings libproxy1-plugin-networkmanager
#apt-get -y --purge --autoremove --no-install-recommends install xfce4 xfce4-goodies xfce4-notifyd pavucontrol xiccd task-desktop/sid task-xfce-desktop/sid
#apt-get -y --purge --autoremove --no-install-recommends install kde-full qml-module-qtwayland-compositor qml-module-qtwayland-client-texturesharing task-kde-desktop/sid task-desktop/sid plasma-workspace-wayland dragonplayer plasma-nm sddm-theme-debian-maui
#apt-get -y --purge --autoremove --install-recommends install task-japanese-desktop/sid
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
options inet6 edns0 trust-ad use-vc
nameserver 192.168.1.2
EOF
chmod a-w /etc/resolv.conf

apt-get -y --purge --autoremove purge ifupdown isc-dhcp-client isc-dhcp-common

exit 0
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
