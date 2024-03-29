**NEW**: kernel build script by **clang** is available at https://gist.github.com/emojifreak/180b335cd58edd9a64fc42b85f735c6d

Built images are available at http://114.150.218.139:63873/RPi-boot-images/ built by `auto-image-builder.sh` **(images refreshed on 16 August 2021 after Debian 11 Bullseye release)**.
**Now these images support USB booting if you have updated the RPi firmware** as https://www.raspberrypi.org/documentation/hardware/raspberrypi/bootmodes/msd.md .

Warning: You need [a recent version of qemu-user-static package](https://packages.debian.org/sid/qemu-user-static). Otherwise the scripts here will probably fail.

# debian-rpi-image-script
Shell script to build Debian SD card image booting the Raspberry Pi series.
Official Debian SD card images are available at https://raspi.debian.net/ Features provided by this shell script are

* GPT partitioning and boot from USB.
* Choice of Debian 10 Buster, 11 Bullseye and later.
* Choice among ifupdown, Network Manager and systemd-networkd for network configuration
* Choice of package coverage according to the [package priority](https://www.debian.org/doc/debian-policy/ch-archive.html#s-priorities)
* btrfs and ext4 filesystems can be chosen as /. btrfs **compress-force=lzo** significantly increases the storage speed and size.
* Setting the size of a swap partition (or lack of it)
* Choice of timezone and locale
* Choice of wireless SSID
* Choice of keyboard layout

If you find **any trouble**, please report it as **a github issue here**.
Other build shell scripts are listed below.

# raspberripyOS-rpi-sd-builder

Use the kernel from Raspberry Pi OS. Except that, it is the same as above. Use of *Gnome Wayland* requires [module_blacklist=v3d](https://github.com/raspberrypi/linux/issues/4202). This is a bug in `gnome-shell`.

# devuan-rpi-image-script
SD card image builder is also available here for Devuan 3 Beowulf, 4 Chimaera and later. Devuan official images are available at https://arm-files.devuan.org/
, which does not have an image for RPi4, but the above script can produce an image booting RPi4 (incl. 8GB model).
**The two shell scripts are similar except packages given as an argument to `mmdebstrap`,**
namely, `systemd-sysv,udev,debian-archive-keyring` versus `sysvinit-core,eudev,devuan-keyring,sntp`.
Hardware clock can be corrected by `sntp -S pool.ntp.org` as root.

# Additional packages
* Graphical User Interface can be installed by `tasksel` or `apt-get install task-xfce-desktop`.
* language supports can be installed, for example, by `apt-get install task-japanese task-japanese-desktop`.

# Running 32-bit kernel on RPi 3 or 4
[32-bit kernel on 64-bit ARM CPU is unsupported by Debian kernel team](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=971059#12), unlike the Raspberry Pi OS. `build-raspi-kernel.sh` can build a 32-bit kernel runnable on RPi 3 and 4. Compilation must be done in a Debian 11 Bullseye armhf (container or VM or a real hardware). The missing config item in the Debian kernel is `CONFIG_PCIE_BRCMSTB=m`, which is turned on only for arm64. 32-bit kernel usable on RPi 3 and 4 are available from http://114.150.218.139:63873/32bit-kernels-for-64bit-raspberrypi/

# Comments on Linux 5.10 and Rapsberry Pi 4 (as of April 2021)
* I **re-compiled** `linux-image-rt-arm64` Debian kernel 5.10.28 by `build-debian-raspi-kernel.sh` here, and made an [IPv4 over IPv6 (MAP-E)](https://www.slideshare.net/akiranakagawa3/20150304-apricot2015apnicfukuoka) router by Raspberry Pi 4B 8GB. It can handle packets at 700 Mbits/sec and has no problem in its packet processing capability. ~~For such a use, it is important to fix the CPU frequency to its highest value and choose the `performance` governer by [linux-cpupower]( https://packages.debian.org/stable/linux-cpupower).~~ `schedutil` governer (the default) is enough.
* `task-xfce-desktop`, `task-gnome-desktop` and `weston` can be used *with no problem* (incl. YouTube on Firefox) on RPi4 Bullseye with the below workarounds.
* Both `vc4.ko` and `snd_bcm2835.ko` accesses to HDMI audio outputs. One should be module_blacklisted. Otherwise, pulseaudio does not work well.
* `drivers/gpu/drm/vc4.ko` enables 4K resolution and DRI/DRM. 4K resolution can be enabled without `vc4.ko` on RPi4 if `hdmi_enable_4kp60=1` is included in `config.txt`.
* But [vc4.ko sometimes garbles display output](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=980785). `disable_fw_kms_setup=1` in `config.txt` often supress this symptom. If `disable_fw_kms_setup=1` does not help, patched kernel package is available at http://153.240.174.134:64193/kernel-deb-5.9/ **The patch was included at Linux 5.10.13**.
* [`gdm3` display manager and gnome session fail with vc4.ko because of insufficient CMA](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=980536). Adding `cma=192M@256M` to `cmdline.txt` fixes this symptom.
* ~~[Boot from USB is impossible](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=977694) unlike Linux 5.9. Kernel package capable of USB boot is available at http://153.240.174.134:64193/kernel-deb-5.9/~~
* WiFi at 5GHz is sometimes blocked by the vc4.ko and high resolution display. `module_blacklist=vc4` in `cmdline.txt` and `hdmi_enable_4kp60=1` could enable both 5GHz WiFi and high resulution simultaneously.
* The above problem is caused by the wrong firmware `/lib/firmware/brcm/brcmfmac43455-sdio.bin` and `/lib/firmware/brcm/brcmfmac43455-sdio.clm_blob`. To fix this, replace those files by https://github.com/RPi-Distro/firmware-nonfree/tree/master/brcm . `brcm-firmware.sh` here replaces the firmware by those in Raspberry Pi OS.
* [5GHz WiFi on RPi4 becomes unusable with firmware-brcm80211 versions newer than 20210201](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=985632). Replacing the above files also fixes this problem.
* ~~Kernel package in the above URL is built by `build-raspi4-kernel.sh` in this directory.~~
* ~~[When kernel is booted from USB, `udisks2` consumes lots of CPU power](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=980980). It can be prevented by `systemctl mask udisks2`.~~

# 32-bit executables on 64-bit linux-image-arm64 kernel
`linux-image-arm64` 64-bit kernel can run `armhf` 32-bit executables. If `armhf,arm64` is given to the above scripts as
the target architecture in place of `armhf` or `arm64`,
then an SD card with 32-bit executables and 64-bit kernel will be built.
It should boot if `debian-rpi-sd-builder.sh` is used.
It will not if `devuan-rpi-sd-builder.sh` is used,
and the following steps are necessary. The difference comes from `systemd-nspawn` versus `chroot`.

1. `mount /dev/mmcblk0p2 /mnt`
2. `mount /dev/mmcblk0p1 /mnt/boot/firmware`
3. `echo arm_64bit=1 >>/mnt/boot/firmware/config.txt`
4. `cp -p /mnt/usr/lib/linux-image-*-arm64/broadcom/bcm*rpi*.dtb /mnt/boot/firmware`
5. `umount /mnt/boot/firmware`
6. `umount /mnt`

# Other image builders
* https://github.com/pyavitz/rpi-img-builder (For Ubuntu, Debian and Devuan)
* https://raspi.debian.net/daily-images/ (for Debian, of course)
* https://evolvis.org/plugins/scmgit/cgi-bin/gitweb.cgi?p=shellsnippets/shellsnippets.git;a=blob;f=posix/mkrpi3b%2Bimg.sh;hb=HEAD (for Debian, RPi3)
* https://github.com/debian-pi/raspbian-ua-netinst

If you find another builder not listed above, please open a github issue. Where is the Ubuntu official builder?

# Debian ARM mailing list
https://lists.debian.org/debian-arm/ is a mailing list for talking Debian ARM related topics, including Raspberry Pi.
