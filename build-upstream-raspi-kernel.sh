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

if [ `dpkg --print-architecture` = arm64 ]; then
  xzcat /usr/src/linux-config-5.10/config.arm64_none_arm64.xz >.config
  apt-get -q -y --install-recommends install g++-arm-linux-gnueabi gcc-arm-linux-gnueabi cpp-arm-linux-gnueabi
  echo 'CONFIG_BPF_JIT_ALWAYS_ON=y' >>.config
  echo 'CONFIG_ZONE_DEVICE=y' >>.config
  echo 'CONFIG_DEVICE_PRIVATE=y' >>.config
elif [ `dpkg --print-architecture` = armhf ]; then
  xzcat /usr/src/linux-config-5.10/config.armhf_none_armmp-lpae.xz >.config
  ARCH=arm
  export ARCH
  cat >>.config <<'EOF'
CONFIG_VIRTUALIZATION=n
CONFIG_ARCH_ASPEED=n
CONFIG_MACH_ASPEED_G6=n
CONFIG_ARCH_BCM=y
CONFIG_ARCH_EXYNOS=n
CONFIG_S5P_DEV_MFC=n
CONFIG_ARCH_EXYNOS4=n
CONFIG_ARCH_EXYNOS5=n
CONFIG_CPU_EXYNOS4210=n
CONFIG_SOC_EXYNOS4412=n
CONFIG_SOC_EXYNOS5250=n
CONFIG_SOC_EXYNOS5260=n
CONFIG_SOC_EXYNOS5410=n
CONFIG_SOC_EXYNOS5420=n
CONFIG_SOC_EXYNOS5800=n
CONFIG_EXYNOS_MCPM=n
CONFIG_EXYNOS_CPU_SUSPEND=n
CONFIG_ARCH_HIGHBANK=n
CONFIG_ARCH_MXC=n
CONFIG_MXC_TZIC=n
CONFIG_HAVE_IMX_ANATOP=n
CONFIG_HAVE_IMX_GPC=n
CONFIG_HAVE_IMX_MMDC=n
CONFIG_HAVE_IMX_SRC=n
CONFIG_SOC_IMX5=n
CONFIG_SOC_IMX51=n
CONFIG_SOC_IMX53=n
CONFIG_SOC_IMX6=n
CONFIG_SOC_IMX6Q=n
CONFIG_SOC_IMX6SL=n
CONFIG_SOC_IMX6SLL=n
CONFIG_SOC_IMX6SX=n
CONFIG_SOC_IMX6UL=n
CONFIG_ARCH_MESON=n
CONFIG_MACH_MESON6=n
CONFIG_MACH_MESON8=n
CONFIG_ARCH_MMP=n
CONFIG_MACH_MMP2_DT=n
CONFIG_ARCH_MVEBU=n
CONFIG_MACH_MVEBU_ANY=n
CONFIG_MACH_MVEBU_V7=n
CONFIG_MACH_ARMADA_370=n
CONFIG_MACH_ARMADA_375=n
CONFIG_MACH_ARMADA_38X=n
CONFIG_MACH_ARMADA_39X=n
CONFIG_MACH_ARMADA_XP=n
CONFIG_MACH_DOVE=n
CONFIG_ARCH_OMAP=n
CONFIG_POWER_AVS_OMAP=n
CONFIG_POWER_AVS_OMAP_CLASS3=n
CONFIG_OMAP_RESET_CLOCKS=n
CONFIG_OMAP_32K_TIMER=n
CONFIG_MACH_OMAP_GENERIC=n
CONFIG_ARCH_OMAP3=n
CONFIG_ARCH_OMAP4=n
CONFIG_SOC_OMAP5=n
CONFIG_SOC_AM33XX=n
CONFIG_SOC_DRA7XX=n
CONFIG_ARCH_OMAP2PLUS=n
CONFIG_OMAP_INTERCONNECT_BARRIER=n
CONFIG_ARCH_OMAP2PLUS_TYPICAL=n
CONFIG_SOC_HAS_OMAP2_SDRC=n
CONFIG_SOC_HAS_REALTIME_COUNTER=n
CONFIG_SOC_OMAP3430=n
CONFIG_SOC_TI81XX=n
CONFIG_OMAP_PACKAGE_CBB=n
CONFIG_MACH_OMAP3517EVM=n
CONFIG_MACH_OMAP3_PANDORA=n
CONFIG_PXA_SSP=m
CONFIG_ARCH_ROCKCHIP=n
CONFIG_ARCH_SOCFPGA=n
CONFIG_ARCH_STM32=n
CONFIG_MACH_STM32MP157=n
CONFIG_ARCH_SUNXI=n
CONFIG_MACH_SUN4I=n
CONFIG_MACH_SUN5I=n
CONFIG_MACH_SUN6I=n
CONFIG_MACH_SUN7I=n
CONFIG_MACH_SUN8I=n
CONFIG_MACH_SUN9I=n
CONFIG_ARCH_SUNXI_MC_SMP=n
CONFIG_ARCH_TEGRA=n
CONFIG_ARCH_VEXPRESS=n
CONFIG_ARCH_VEXPRESS_CORTEX_A5_A9_ERRATA=n
CONFIG_ARCH_VT8500=n
CONFIG_ARCH_WM8850=n
CONFIG_PLAT_ORION=n
CONFIG_PLAT_PXA=n
CONFIG_PLAT_VERSATILE=n
EOF
else
  echo "Unknown architecture"
  exit 1
fi
cp .config .config-orig
cat >>.config <<'EOF'
CONFIG_HZ_250=n
CONFIG_HZ_100=y
CONFIG_LOCALVERSION=-preempt
CONFIG_PREEMPT=y
CCONFIG_HOTPLUG_CPU=n
CONFIG_NUMA=n
ONFIG_ACPI=n
CONFIG_EFI=n
CONFIG_LATENCYTOP=y
CONFIG_DEBUG_INFO=n
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
CONFIG_IP_VS_TWOS=m
CONFIG_SUSPEND=n
CONFIG_HIBERNATION=n
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
CONFIG_LEDS_TRIGGER_TTY=m
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
#CONFIG_PM=n
EOF

if [ -t 0 ]; then
  config=oldconfig
else
  config=olddefconfig
fi

if [ `dpkg --print-architecture` = arm64 ]; then
  make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_COMPAT=arm-linux-gnueabi- $config
else
  make $config
fi

if [ -t 0 ]; then
  diff -u .config-orig .config | less
  echo "Hit Enter to proceed."
  read tmp
else
  set +e
  diff -u .config-orig .config
  set -e
fi

if [ `dpkg --print-architecture` = arm64 ]; then
  make -j 4 ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_COMPAT=arm-linux-gnueabi- bindeb-pkg
else
  make -j 4 bindeb-pkg
fi
