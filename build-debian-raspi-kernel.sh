#!/bin/bash

KVER=5.10.28
mkdir -p $HOME/build-${KVER}
cd $HOME/build-${KVER}
set -xe
apt-get source linux
cd linux-$KVER

# See
# https://www.debian.org/doc/manuals/debian-kernel-handbook/ch-common-tasks.html#s4.2.3
fakeroot make -f debian/rules.gen setup_arm64_rt_arm64
cat >>debian/build/build_arm64_rt_arm64/.config <<'EOF'
CONFIG_LOCALVERSION=-preemptrt
CONFIG_PREEMPT_RT=y
CONFIG_HOTPLUG_CPU=n
CONFIG_NUMA=n
CONFIG_VIRTUALIZATION=n
CONFIG_ACPI=n
CONFIG_EFI=n
CONFIG_LATENCYTOP=y
CONFIG_DEBUG_PREEMPT=n
CONFIG_FORTIFY_SOURCE=y
CONFIG_UBSAN=y
CONFIG_UBSAN_BOUNDS=y
CONFIG_UBSAN_SANITIZE_ALL=y
CONFIG_UBSAN_MISC=y
CONFIG_UBSAN_UNREACHABLE=y
CONFIG_SCHED_STACK_END_CHECK=y
CONFIG_DEBUG_TIMEKEEPING=y
CONFIG_BUG_ON_DATA_CORRUPTION=y
CONFIG_KFENCE=y
CONFIG_STACK_VALIDATION=y
CONFIG_WQ_WATCHDOG=y
CONFIG_NFT_REJECT_NETDEV=m
CONFIG_SUSPEND=n
CONFIG_HIBERNATION=n
CONFIG_BPF_JIT_ALWAYS_ON=y
CONFIG_ZONE_DEVICE=y
CONFIG_DEVICE_PRIVATE=y
CONFIG_PARAVIRT=n
CONFIG_XEN=n
CONFIG_CLEANCACHE=y
CONFIG_BLK_CGROUP_IOLATENCY=y
CONFIG_SCSI_DEBUG=m
CONFIG_IRQ_TIME_ACCOUNTING=y
CONFIG_SCHED_THERMAL_PRESSURE=y
CONFIG_UCLAMP_TASK=y
CONFIG_UCLAMP_TASK_GROUP=y
CONFIG_IKCONFIG=m
CONFIG_IKCONFIG_PROC=y
CONFIG_RESET_RASPBERRYPI=m
CONFIG_ARM_RASPBERRYPI_CPUFREQ=m
CONFIG_SENSORS_RASPBERRYPI_HWMON=m
CONFIG_TOUCHSCREEN_RASPBERRYPI_FW=m
CONFIG_REGULATOR_RASPBERRYPI_TOUCHSCREEN_ATTINY=m
CONFIG_DRM_PANEL_RASPBERRYPI_TOUCHSCREEN=m
CONFIG_PI433=m
CONFIG_PCIE_BRCMSTB=m

# ARM64 architectures other than RPi
CONFIG_ARCH_N5X=n
CONFIG_ARCH_ACTIONS=n
CONFIG_ARCH_AGILEX=n
CONFIG_ARCH_SUNXI=n
CONFIG_ARCH_ALPINE=n
CONFIG_ARCH_BCM2835=y
CONFIG_ARCH_BCM4908=n
CONFIG_ARCH_BCM_IPROC=n
CONFIG_ARCH_BERLIN=n
CONFIG_ARCH_BITMAIN=n
CONFIG_ARCH_BRCMSTB=n
CONFIG_ARCH_EXYNOS=n
CONFIG_ARCH_SPARX5=n
CONFIG_ARCH_K3=n
CONFIG_ARCH_LAYERSCAPE=n
CONFIG_ARCH_LG1K=n
CONFIG_ARCH_HISI=n
CONFIG_ARCH_KEEMBAY=n
CONFIG_ARCH_MEDIATEK=n
CONFIG_ARCH_MESON=n
CONFIG_ARCH_MVEBU=n
CONFIG_ARCH_MXC=n
CONFIG_ARCH_QCOM=n
CONFIG_ARCH_REALTEK=n
CONFIG_ARCH_RENESAS=n
CONFIG_ARCH_ROCKCHIP=n
CONFIG_ARCH_S32=n
CONFIG_ARCH_SEATTLE=n
CONFIG_ARCH_STRATIX10=n
CONFIG_ARCH_SYNQUACER=n
CONFIG_ARCH_TEGRA=n
CONFIG_ARCH_SPRD=n
CONFIG_ARCH_THUNDER=n
CONFIG_ARCH_THUNDER2=n
CONFIG_ARCH_UNIPHIER=n
CONFIG_ARCH_VEXPRESS=n
CONFIG_ARCH_VISCONTI=n
CONFIG_ARCH_XGENE=n
CONFIG_ARCH_ZX=n
CONFIG_ARCH_ZYNQMP=n
CONFIG_SURFACE_PLATFORMS=n
EOF
fakeroot debian/rules source
fakeroot make -j 4 -f debian/rules.gen binary-arch_arm64_rt_arm64
