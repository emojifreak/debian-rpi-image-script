#!/bin/bash

echo -n "Kernel version: "
read KVAR
set -xe
wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-${KVAR}.tar.xz
tar Jxf linux-${KVAR}.tar.xz &
pid=$!
apt-get -q -y update
set +e
apt-get --purge dist-upgrade
set -e
apt-get -q -y install linux-config-5.10/sid
apt-get -q -y install build-essential libncurses-dev fakeroot dpkg-dev
apt-get -q -y build-dep linux/sid
wait $pid
cd linux-${KVAR}


xzcat /usr/src/linux-config-5.10/config.arm64_none_arm64.xz >.config
cp .config .config-orig
cat >>.config <<'EOF'
CONFIG_LOCALVERSION="-preempt"
CONFIG_BPF_JIT_ALWAYS_ON=y
CONFIG_USERFAULTFD=y
CONFIG_RSEQ=y
CONFIG_PREEMPT=y
CONFIG_VIRT_CPU_ACCOUNTING_NATIVE=y
CONFIG_IRQ_TIME_ACCOUNTING=y
CONFIG_SCHED_THERMAL_PRESSURE=y
#CONFIG_RT_GROUP_SCHED=y
CONFIG_UCLAMP_TASK=y
CONFIG_UCLAMP_TASK_GROUP=y
CONFIG_TASKSTATS=y
CONFIG_TASK_DELAY_ACCT=y
CONFIG_TASK_XACCT=y
CONFIG_TASK_IO_ACCOUNTING=y
CONFIG_IKCONFIG=m
CONFIG_IKCONFIG_PROC=y
CONFIG_BLK_CGROUP=y
CONFIG_BFQ_GROUP_IOSCHED=y
CONFIG_BLK_DEV_THROTTLING=y
CONFIG_RESET_RASPBERRYPI=m
CONFIG_ARM_RASPBERRYPI_CPUFREQ=m
CONFIG_SENSORS_RASPBERRYPI_HWMON=m
CONFIG_TOUCHSCREEN_RASPBERRYPI_FW=m
CONFIG_REGULATOR_RASPBERRYPI_TOUCHSCREEN_ATTINY=m
CONFIG_DRM_PANEL_RASPBERRYPI_TOUCHSCREEN=m
CONFIG_PI433=m
CONFIG_CC_OPTIMIZE_FOR_SIZE=y
CONFIG_MQ_IOSCHED_KYBER=y
CONFIG_IOSCHED_BFQ=y
CONFIG_DRM_VC4=m
CONFIG_DRM_VC4_HDMI_CEC=y
#CONFIG_VDPA=m
CONFIG_NTFS_FS=m
CONFIG_DEBUG_INFO=n
CONFIG_PM=n
CONFIG_SUSPEND=n
CONFIG_HIBERNATION=n
# Triggers enablement via hibernate callbacks
CONFIG_XEN=n
# ARM/ARM64 architectures that select PM unconditionally
CONFIG_ARCH_OMAP2PLUS_TYPICAL=n
CONFIG_ARCH_RENESAS=n
CONFIG_ARCH_TEGRA=n
CONFIG_ARCH_VEXPRESS=n
EOF
make oldconfig
diff -u .config-orig .config | less
echo "Hit Enter to proceed."
read tmp
nice -19 make -j 12 bindeb-pkg

if ! fgrep -q reset /etc/initramfs-tools/modules /usr/share/initramfs-tools/modules.d/*; then
  echo "reset_raspberrypi" >>/etc/initramfs-tools/modules
  echo 'reset_raspberrypi is added to /etc/initramfs-tools/modules.'
fi

#CONFIG_ARCH_BCM_IPROC=y
#CONFIG_ARCH_BRCMSTB=y
#CONFIG_ARCH_BCM4908=y
