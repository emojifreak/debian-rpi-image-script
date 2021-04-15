#!/bin/sh

apt-get install firmware-brcm80211
apt-mark hold  firmware-brcm80211
cd /tmp
rm -rf firmware-nonfree
set -ex
git clone https://github.com/RPi-Distro/firmware-nonfree
cd firmware-nonfree/brcm
dir=/lib/firmware/brcm
for i in *; do
  rm -f $dir/"$i"
  cp -p "$i" $dir
done
