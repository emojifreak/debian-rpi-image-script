# debian-rpi-image-script
Shell script to build Debian SD card image booting the Raspberry Pi series.
Official Debian SD card images are available at https://raspi.debian.net/ Features provided by this shell script are

* Choice of package coverage according to the [package priority](https://www.debian.org/doc/debian-policy/ch-archive.html#s-priorities)
* btrfs and ext4 filesystems can be chosen as /
* Setting the size of a swap partition (or lack of it)
* Choice of timezone and locale
* Choice of wireless SSID
* Choice of keyboard layout
* Debian 11 Bullseye

An SD card must be set in `/dev/mmcblk0`. If you find **any trouble**, please report it as **a github issue here**.

# devuan-rpi-image-script
SD card image builder is also available here for Devuan 4 Chimaera. Devuan official images are available at https://arm-files.devuan.org/
 , which does not have an image for RPi4, but the above script can produce an image booting RPi4 (incl. 8GB model).
 You may have to [install the Devuan keyring](https://www.devuan.org/os/keyring) before running the script.
 Qestions and comments (not issue reports) can be posted at http://dev1galaxy.org/viewtopic.php?pid=25115
 The two shell scripts are the same except packages given as an argument to `mmdebstrap`.

# Additional packages
* language supports can be installed, for example, by `apt-get install task-japanese task-japanese-desktop`.
* Graphical User Interface can be installed by `tasksel`.
