# debian-rpi-image-script
Shell script to build Debian SD card image booting the Raspberry Pi series
Official SD card images are available at https://raspi.debian.net/ Features provided by this shell script are

* Choice of package coverage according to the [package priority](https://www.debian.org/doc/debian-policy/ch-archive.html#s-priorities)
* Choice of timezone and locale
* Choice of wireless SSID
* Choice of keyboard layout
* Debian 11 Bullseye

An SD card must be set in `/dev/mmcblk0`
