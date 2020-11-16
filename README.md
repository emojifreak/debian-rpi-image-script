Built images are available at https://drive.google.com/drive/folders/1-L5pT4tn7wfxp9urjnIDL2SvAbxO8Vl6?usp=sharing

Warning: You need [a recent version of qemu-user-static package](https://packages.debian.org/bullseye/qemu-user-static). Otherwise the scripts here will probably fail.

# debian-rpi-image-script
Shell script to build Debian SD card image booting the Raspberry Pi series.
Official Debian SD card images are available at https://raspi.debian.net/ Features provided by this shell script are

* Choice of Debian 10 Buster, 11 Bullseye and later.
* Choice among ifupdown, Network Manager and systemd-networkd for network configuration
* Choice of package coverage according to the [package priority](https://www.debian.org/doc/debian-policy/ch-archive.html#s-priorities)
* btrfs and ext4 filesystems can be chosen as /. btrfs **compress-force=lzo** significantly increases the storage speed and size.
* Setting the size of a swap partition (or lack of it)
* Choice of timezone and locale
* Choice of wireless SSID
* Choice of keyboard layout

An SD card must be set in `/dev/mmcblk0` or change the script. If you find **any trouble**, please report it as **a github issue here**.
Other build shell scripts are listed below.

# devuan-rpi-image-script
SD card image builder is also available here for Devuan 3 Beowulf, 4 Chimaera and later. Devuan official images are available at https://arm-files.devuan.org/
, which does not have an image for RPi4, but the above script can produce an image booting RPi4 (incl. 8GB model).
You may have to [install the Devuan keyring](https://www.devuan.org/os/keyring) before running the script.
Qestions and comments (not issue reports) can be posted at http://dev1galaxy.org/viewtopic.php?pid=25115
**The two shell scripts are similar except packages given as an argument to `mmdebstrap`,**
namely, `systemd-sysv,udev,debian-archive-keyring` versus `sysvinit-core,eudev,devuan-keyring,sntp`.
Hardware clock can be corrected by `sntp -S pool.ntp.org` as root.

# Additional packages
* language supports can be installed, for example, by `apt-get install task-japanese task-japanese-desktop`.
* Graphical User Interface can be installed by `tasksel`.

# 32-bit executables on 64-bit linux-image-arm64 kernel
`linux-image-arm64` 64-bit kernel can run `armhf` 32-bit executables. If `armhf,arm64` is given to the above scripts as
the target architecture in place of `armhf` or `arm64`,
then an SD card with 32-bit executables and 64-bit kernel will be built. But
[it does not boot](https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=971748). To make it bootable,
do the following steps as root after running the above script:

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

If you find another builder not listed above, please open a github issue. Where is the Ubuntu official builder?
