#!/bin/bash

mkdir -p /root/build
cd /root/build
#echo -n "Kernel version: "
#read KVAR
KVAR=5.10.58
exec </dev/null >/root/build-log-${KVAR}-`date +%F-%T`.txt 2>&1
set -xe
#echo zbud > /sys/module/zswap/parameters/zpool
#echo lzo > /sys/module/zswap/parameters/compressor
#echo 1 > /sys/module/zswap/parameters/enabled
wget -T 10 https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-${KVAR}.tar.xz 
#wget -T 10 https://git.kernel.org/torvalds/t/linux-5.14-rc5.tar.gz
tar Jxf linux-${KVAR}.tar.xz &
#tar zxf linux-${KVAR}.tar.gz &
pid=$!
#wget -T 10 https://cdn.kernel.org/pub/linux/kernel/projects/rt/5.10/patch-5.10.47-rt45.patch.xz
#tar Jxf patches-${KVAR}-rt${RTVAR}.tar.xz &
#apt-get -q -y update
set +e
#apt-get -y -q --purge dist-upgrade
set -e
#apt-get -q -y install linux-config-5.14/sid
#apt-get -q -y install build-essential libncurses-dev fakeroot dpkg-dev
#apt-get -q -y build-dep linux/sid
wait $pid
cd linux-${KVAR}
#xzcat ../patch-5.10.47-rt45.patch.xz | patch -p1 
#xzcat ../patch-5.10.27-rt${RTVAR}.patch.xz | patch -p1
if [ `dpkg --print-architecture` = arm64 ]; then
  xzcat /usr/src/linux-config-5.10/config.arm64_none_arm64.xz >.config
  #cat /root/ltoyes.txt >>.config
  echo 'CONFIG_BPF_JIT_ALWAYS_ON=y' >>.config
  echo 'CONFIG_ZONE_DEVICE=y' >>.config
  echo 'CONFIG_DEVICE_PRIVATE=y' >>.config
  echo 'CONFIG_ARCH_MMAP_RND_BITS=33' >>.config
  echo 'CONFIG_ARCH_MMAP_RND_COMPAT_BITS=16' >>.config
  echo 'CONFIG_ARM64_SW_TTBR0_PAN=y' >>.config
  echo 'CONFIG_VIRTUALIZATION=y' >>.config
elif [ `dpkg --print-architecture` = armhf ]; then
  xzcat /usr/src/linux-config-5.10/config.armhf_none_armmp-lpae.xz >.config
  ARCH=arm
  export ARCH
  cat >>.config <<'EOF'
CONFIG_VIRTUALIZATION=n
CONFIG_ARCH_MMAP_RND_BITS=16
CONFIG_CPU_SW_DOMAIN_PAN=y
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
CONFIG_CC_OPTIMIZE_FOR_PERFORMANCE=y
CONFIG_CC_OPTIMIZE_FOR_SIZE=n

CONFIG_RCU_EXPERT=y
CONFIG_RCU_BOOST=y
CONFIG_TASKS_TRACE_RCU_READ_MB=y
#CONFIG_KASAN=y
#CONFIG_KASAN_SW_TAGS=y
#CONFIG_KASAN_INLINE=y
#CONFIG_KASAN_TAGS_IDENTIFY=y

CONFIG_TRANSPARENT_HUGEPAGE_ALWAYS=n
CONFIG_TRANSPARENT_HUGEPAGE_MADVISE=y
CONFIG_NET_RX_BUSY_POLL=n


CONFIG_USB_DWC3=n
CONFIG_USB_DWC3_HAPS=n
CONFIG_USB_DWC3_OF_SIMPLE=n
CONFIG_USB_DWC2=n

CONFIG_FTRACE=n
CONFIG_FUNCTION_TRACER=n
CONFIG_HOTPLUG_PCI=n
CONFIG_HOTPLUG_PCI_PCIE=n


CONFIG_PPP=n
CONFIG_SLIP=n
CONFIG_USB_NET_DRIVERS=n

CONFIG_ORANGEFS_FS=n
CONFIG_ADFS_FS=n
CONFIG_AFFS_FS=n
CONFIG_ECRYPT_FS=n
CONFIG_HFS_FS=n
CONFIG_HFSPLUS_FS=n
CONFIG_BEFS_FS=n
CONFIG_BFS_FS=n
CONFIG_EFS_FS=n
CONFIG_JFFS2_FS=n
CONFIG_UBIFS_FS=n
CONFIG_VXFS_FS=n
CONFIG_MINIX_FS=n
CONFIG_OMFS_FS=n
CONFIG_HPFS_FS=n
CONFIG_QNX4FS_FS=n
CONFIG_QNX6FS_FS=n
CONFIG_ROMFS_FS=n
CONFIG_SYSV_FS=n
CONFIG_UFS_FS=n
CONFIG_EROFS_FS=n
CONFIG_NFS_FS=n
CONFIG_CODA_FS=n
CONFIG_AFS_FS=n
CONFIG_9P_FS=n
CONFIG_SQUASHFS=n
CONFIG_CIFS=n
CONFIG_CHELSIO_T1=n
CONFIG_CHELSIO_T1_1G=n
CONFIG_CHELSIO_T3=n
CONFIG_CHELSIO_T4=n
CONFIG_CHELSIO_T4VF=n
CONFIG_CHELSIO_LIB=n
CONFIG_CHELSIO_INLINE_CRYPTO=n
CONFIG_SCSI_CHELSIO_FCOE=n
CONFIG_CRYPTO_HW=n
CONFIG_CEPH_FS=n
CONFIG_CEPH_LIB=n
CONFIG_NETFS_SUPPORT=n
CONFIG_DNS_RESOLVER=n


CONFIG_BLK_CGROUP_IOPRIO=y
CONFIG_SECCOMP_CACHE_DEBUG=y
CONFIG_CMA_SYSFS=y
CONFIG_DEFAULT_BBR=y
CONFIG_DEFAULT_CUBIC=n
CONFIG_DEFAULT_TCP_CONG="bbr"
CONFIG_NF_LOG_SYSLOG=y
CONFIG_NETFILTER_XTABLES_COMPAT=n
CONFIG_ATM=n
CONFIG_NET_VENDOR_CHELSIO=n

CONFIG_NR_CPUS=4
CONFIG_SCHED_MC=y
CONFIG_SCHED_SMT=y
CONFIG_SCHED_CORE=y
CONFIG_LOCK_EVENT_COUNTS=y
CONFIG_HAMRADIO=n
CONFIG_CAN=n
CONFIG_BT_MSFTEXT=y
CONFIG_BT_AOSPEXT=y
CONFIG_NFC=n
CONFIG_GNSS=n
CONFIG_FIREWIRE=n
CONFIG_ACCESSIBILITY=n
CONFIG_INFINIBAND=n
CONFIG_ANDROID=n
CONFIG_TEE=n
CONFIG_DRM_RADEON=n
CONFIG_DRM_AMDGPU=n
CONFIG_DRM_NOUVEAU=n
CONFIG_DRM_AST=n
CONFIG_DRM_QXL=n
CONFIG_DRM_BOCHS=n
CONFIG_DRM_VIRTIO_GPU=n
CONFIG_VIRTIO=n
CONFIG_DRM_SIMPLEDRM=m
CONFIG_MEMSTICK=n
CONFIG_VFIO=n
CONFIG_REISERFS_FS=n
CONFIG_JFS_FS=n
CONFIG_GFS2_FS=n
CONFIG_OCFS2_FS=n
CONFIG_NILFS2_FS=n
CONFIG_F2FS_FS=n
CONFIG_ZONEFS_FS=n
CONFIG_EXFAT_FS=m
CONFIG_DLM=n
CONFIG_IP_DCCP=n
CONFIG_IP_SCTP=n
CONFIG_RDS=n
CONFIG_TIPC=n
CONFIG_ATALK=n
CONFIG_X25=n
CONFIG_PHONET=n
CONFIG_6LOWPAN=n
CONFIG_DCB=n
CONFIG_BATMAN_ADV=n
CONFIG_QRTR=n

CONFIG_NET_VENDOR_3COM=n
CONFIG_NET_VENDOR_ADAPTEC=n
CONFIG_NET_VENDOR_AGERE=n
CONFIG_NET_VENDOR_ALACRITECH=n
CONFIG_NET_VENDOR_ALTEON=n
CONFIG_NET_VENDOR_AMAZON=n
CONFIG_NET_VENDOR_AMD=n
CONFIG_NET_VENDOR_AQUANTIA=n
CONFIG_NET_VENDOR_ARC=n
CONFIG_NET_VENDOR_ATHEROS=n
CONFIG_NET_VENDOR_BROADCOM=y
CONFIG_NET_VENDOR_BROCADE=n
CONFIG_NET_VENDOR_CADENCE=n
CONFIG_NET_VENDOR_CAVIUM=n
CONFIG_NET_VENDOR_CHELSIO=n
CONFIG_NET_VENDOR_CISCO=n
CONFIG_NET_VENDOR_CORTINA=n
CONFIG_NET_VENDOR_DEC=n
CONFIG_NET_VENDOR_DLINK=n
CONFIG_NET_VENDOR_EMULEX=n
CONFIG_NET_VENDOR_EZCHIP=n
CONFIG_NET_VENDOR_GOOGLE=n
CONFIG_NET_VENDOR_HISILICON=n
CONFIG_NET_VENDOR_HUAWEI=n
CONFIG_NET_VENDOR_I825XX=n
CONFIG_NET_VENDOR_INTEL=n
CONFIG_NET_VENDOR_MICROSOFT=n
CONFIG_NET_VENDOR_MARVELL=n
CONFIG_NET_VENDOR_MELLANOX=n
CONFIG_NET_VENDOR_MICREL=n
CONFIG_NET_VENDOR_MICROCHIP=n
CONFIG_NET_VENDOR_MICROSEMI=n
CONFIG_NET_VENDOR_MYRI=n
CONFIG_NET_VENDOR_NATSEMI=n
CONFIG_NET_VENDOR_NETERION=n
CONFIG_NET_VENDOR_NETRONOME=n
CONFIG_NET_VENDOR_NI=n
CONFIG_NET_VENDOR_8390=n
CONFIG_NET_VENDOR_NVIDIA=n
CONFIG_NET_VENDOR_OKI=n
CONFIG_NET_VENDOR_PACKET_ENGINES=n
CONFIG_NET_VENDOR_PENSANDO=n
CONFIG_NET_VENDOR_QLOGIC=n
CONFIG_NET_VENDOR_QUALCOMM=n
CONFIG_NET_VENDOR_RDC=n
CONFIG_NET_VENDOR_REALTEK=n
CONFIG_NET_VENDOR_RENESAS=n
CONFIG_NET_VENDOR_ROCKER=n
CONFIG_NET_VENDOR_SAMSUNG=n
CONFIG_NET_VENDOR_SEEQ=n
CONFIG_NET_VENDOR_SOLARFLARE=n
CONFIG_NET_VENDOR_SILAN=n
CONFIG_NET_VENDOR_SIS=n
CONFIG_NET_VENDOR_SMSC=n
CONFIG_NET_VENDOR_SOCIONEXT=n
CONFIG_NET_VENDOR_STMICRO=n
CONFIG_NET_VENDOR_SUN=n
CONFIG_NET_VENDOR_SYNOPSYS=n
CONFIG_NET_VENDOR_TEHUTI=n
CONFIG_NET_VENDOR_TI=n
CONFIG_NET_VENDOR_VIA=n
CONFIG_NET_VENDOR_WIZNET=n
CONFIG_NET_VENDOR_XILINX=n
CONFIG_WLAN_VENDOR_ADMTEK=n
CONFIG_WLAN_VENDOR_ATH=n
CONFIG_WLAN_VENDOR_ATMEL=n
CONFIG_WLAN_VENDOR_BROADCOM=y
CONFIG_WLAN_VENDOR_CISCO=n
CONFIG_WLAN_VENDOR_INTEL=n
CONFIG_WLAN_VENDOR_INTERSIL=n
CONFIG_WLAN_VENDOR_MARVELL=n
CONFIG_WLAN_VENDOR_MEDIATEK=n
CONFIG_WLAN_VENDOR_MICROCHIP=n
CONFIG_WLAN_VENDOR_RALINK=n
CONFIG_WLAN_VENDOR_REALTEK=n
CONFIG_WLAN_VENDOR_RSI=n
CONFIG_WLAN_VENDOR_ST=n
CONFIG_WLAN_VENDOR_TI=n
CONFIG_WLAN_VENDOR_ZYDAS=n
CONFIG_WLAN_VENDOR_QUANTENNA=n


CONFIG_CPU_FREQ_DEFAULT_GOV_PERFORMANCE=y
CONFIG_BRCM_TRACING=y
CONFIG_BRCMDBG=y
CONFIG_BRCMFMAC=m
CONFIG_XFS_FS=n
CONFIG_CFG80211=m
CONFIG_NL80211_TESTMODE=n
CONFIG_CFG80211_DEVELOPER_WARNINGS=n
CONFIG_CFG80211_CERTIFICATION_ONUS=y
CONFIG_CFG80211_REQUIRE_SIGNED_REGDB=n
CONFIG_CFG80211_REG_CELLULAR_HINTS=n
CONFIG_CFG80211_REG_RELAX_NO_IR=n
CONFIG_CFG80211_DEFAULT_PS=y
CONFIG_CFG80211_DEBUGFS=y
CONFIG_CFG80211_CRDA_SUPPORT=y
CONFIG_CFG80211_WEXT=y


CONFIG_CMA_DEBUGFS=y
CONFIG_IOMMU_DEBUGFS=n
CONFIG_CFG80211_DEBUGFS=y
CONFIG_MAC80211_DEBUGFS=y
CONFIG_GENERIC_IRQ_DEBUGFS=y
CONFIG_ZSMALLOC_STAT=y

CONFIG_VGA_ARB=n
CONFIG_DEVPORT=n
CONFIG_SND_OSSEMUL=n
CONFIG_SOUND_OSS_CORE=n
CONFIG_USB_EHCI_HCD=n
CONFIG_USB_OHCI_HCD=n


CONFIG_LD_DEAD_CODE_DATA_ELIMINATION=y
CONFIG_TRIM_UNUSED_KSYMS=y
CONFIG_DEBUG_KMEMLEAK=n
CONFIG_DEBUG_STACK_USAGE=y
CONFIG_DEBUG_SECTION_MISMATCH=y
CONFIG_SECTION_MISMATCH_WARN_ONLY=n
CONFIG_MEMTEST=y
CONFIG_WARN_ALL_UNSEEDED_RANDOM=n
CONFIG_DEBUG_SHIRQ=y

#Maybe slow...
CONFIG_DEBUG_PREEMPT=y
CONFIG_LOCK_STAT=y
CONFIG_DEBUG_OBJECTS=y
CONFIG_DEBUG_OBJECTS_ENABLE_DEFAULT=1



CONFIG_INIT_STACK_NONE=y
CONFIG_INIT_STACK_ALL_PATTERN=y
CONFIG_SHADOW_CALL_STACK=y
CONFIG_LTO_NONE=n
CONFIG_LTO_CLANG_FULL=y
CONFIG_CFI_CLANG=y
CONFIG_CFI_CLANG_SHADOW=y
CONFIG_CFI_PERMISSIVE=y

CONFIG_AS_HAS_LDAPR=n
CONFIG_AS_HAS_LSE_ATOMICS=n
CONFIG_AS_HAS_PAC=n
CONFIG_AS_HAS_CFI_NEGATE_RA_STATE=n
CONFIG_AS_HAS_ARMV8_4=n
CONFIG_AS_HAS_ARMV8_5=n
CONFIG_ARM64_AS_HAS_MTE=n


CONFIG_CRYPTO_AEGIS128_SIMD=n
CONFIG_ARM64_HW_AFDBM=n
CONFIG_ARM64_PAN=n
CONFIG_AS_HAS_LSE_ATOMICS=n
CONFIG_ARM64_LSE_ATOMICS=n
CONFIG_ARM64_USE_LSE_ATOMICS=n
CONFIG_ARM64_VHE=n
CONFIG_ARM64_UAO=n
CONFIG_ARM64_PMEM=n
CONFIG_ARM64_RAS_EXTN=n
CONFIG_ARM64_CNP=n
CONFIG_ARM64_PTR_AUTH=n
CONFIG_CC_HAS_BRANCH_PROT_PAC_RET=n
CONFIG_CC_HAS_SIGN_RETURN_ADDRESS=n
CONFIG_AS_HAS_PAC=n
CONFIG_AS_HAS_CFI_NEGATE_RA_STATE=n
CONFIG_ARM64_AMU_EXTN=n
CONFIG_AS_HAS_ARMV8_4=n
CONFIG_ARM64_TLB_RANGE=n
CONFIG_ARM64_BTI=n
CONFIG_ARM64_BTI_KERNEL=n
CONFIG_CC_HAS_BRANCH_PROT_PAC_RET_BTI=n
CONFIG_ARM64_E0PD=n
CONFIG_ARCH_RANDOM=n
CONFIG_ARM64_AS_HAS_MTE=n
CONFIG_ARM64_MTE=n
CONFIG_MQ_IOSCHED_DEADLINE=m
CONFIG_MQ_IOSCHED_KYBER=m
CONFIG_IOSCHED_BFQ=y
CONFIG_ARM_SMMU_V3_SVA=y
CONFIG_GOOGLE_FIRMWARE=n
CONFIG_CHROME_PLATFORMS=n

CONFIG_ARM_PSCI_FW=n
CONFIG_CPU_IDLE=n
CONFIG_USERFAULTFD=n
CONFIG_CGROUP_MISC=y
CONFIG_ARCH_APPLE=n
CONFIG_ARCH_INTEL_SOCFPGA=n
CONFIG_RANDOMIZE_KSTACK_OFFSET_DEFAULT=y
CONFIG_NET_VENDOR_MICROSOFT=n
CONFIG_PWM_RASPBERRYPI_POE=m
CONFIG_NVMEM_RMEM=m
CONFIG_NETFS_STATS=y
CONFIG_UBSAN_SHIFT=y
CONFIG_DEBUG_IRQFLAGS=y
CONFIG_HZ_250=n
CONFIG_HZ_100=y
CONFIG_PREEMPT_VOLUNTARY=n
CONFIG_PREEMPT=y
# https://wiki.linuxfoundation.org/realtime/documentation/howto/applications/preemptrt_setup
CONFIG_HOTPLUG_CPU=n
CONFIG_NUMA=n
CONFIG_ACPI=n
CONFIG_EFI=n
CONFIG_SECURITY_TOMOYO=n
CONFIG_LATENCYTOP=y
CONFIG_DEBUG_INFO=n
CONFIG_FORTIFY_SOURCE=y
CONFIG_UBSAN=y
CONFIG_UBSAN_BOUNDS=y
CONFIG_UBSAN_SANITIZE_ALL=y
CONFIG_UBSAN_MISC=y
CONFIG_UBSAN_UNREACHABLE=y
CONFIG_SCHED_STACK_END_CHECK=y
#CONFIG_DEBUG_TIMEKEEPING=y
CONFIG_BUG_ON_DATA_CORRUPTION=y
CONFIG_KFENCE=y
CONFIG_STACK_VALIDATION=y
CONFIG_WQ_WATCHDOG=y
CONFIG_NFT_REJECT_NETDEV=m
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
CONFIG_SENSORS_RASPBERRYPI_HWMON=m
CONFIG_TOUCHSCREEN_RASPBERRYPI_FW=n
CONFIG_REGULATOR_RASPBERRYPI_TOUCHSCREEN_ATTINY=n
CONFIG_DRM_PANEL_RASPBERRYPI_TOUCHSCREEN=n

CONFIG_ARM_RASPBERRYPI_CPUFREQ=y
CONFIG_RESET_RASPBERRYPI=y
CONFIG_PCIE_BRCMSTB=y
CONFIG_BLK_DEV_SD=y
CONFIG_SCSI=y
CONFIG_SCSI_DMA=y
CONFIG_USB_XHCI_PCI=y
CONFIG_BCMGENET=y
CONFIG_TCP_CONG_BBR=y
CONFIG_NET_SCH_FIFO=y
CONFIG_CRYPTO_JITTERENTROPY=y
CONFIG_HW_RANDOM_IPROC_RNG200=y
CONFIG_MACVLAN=y
CONFIG_MACVTAP=y
CONFIG_IPV6_TUNNEL=y
CONFIG_INET6_TUNNEL=y
CONFIG_EXT4_FS=y
CONFIG_JBD2=y
CONFIG_USB_STORAGE=y
CONFIG_USB_UAS=y


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

CONFIG_COMPAT_VDSO=n
CONFIG_DEVMEM=n
CONFIG_DEFAULT_MMAP_MIN_ADDR=32768
CONFIG_KEXEC=n
EOF

if false; then
cat >>.config <<EOF
CONFIG_CC_OPTIMIZE_FOR_PERFORMANCE=n
CONFIG_CC_OPTIMIZE_FOR_SIZE=y
EOF

#cat $HOME/ltoyes.txt >>.config 

#sed -i 's/-O2/-O3/g' Makefile
#sed -i 's/-Os/-Oz/g' Makefile
sed -i 's/-fno-stack-clash-protection/-fstack-clash-protection/g' Makefile
#sed -i 's/-flto/-flto -fwhole-program-vtables -fvirtual-function-elimination/g' Makefile

# See http://senthilthecoder.com/post/lto-linker-commandline/

# chrt --idle 0 nice -19

yes '' |  nice /usr/bin/time -v make -j 4 V=1 LLVM=1 LLVM_IAS=1 KCFLAGS="-pipe -march=armv8-a+crc -mtune=cortex-a72 -faddrsig" LDFLAGS_vmlinux="--icf=all --print-icf-sections" LDFLAGS_MODULE="${LDFLAGS_vmlinux}" LOCALVERSION=-clang12icf CC=clang-12 LD=ld.lld-12 AR=llvm-ar-12 NM=llvm-nm-12 STRIP=llvm-strip-12  OBJCOPY=llvm-objcopy-12 OBJDUMP=llvm-objdump-12 READELF=llvm-readelf-12  HOSTCC=clang-12 HOSTCXX=clang++-12 CXX=clang++-12 HOSTAR=llvm-ar-12 HOSTLD=ld.lld-12 bindeb-pkg
cp -f .config /root/last-build-config-${KVAR}.txt

exit 0
fi

yes '' | nice -19 /usr/bin/time -v make -j 5  LLVM=1 LLVM_IAS=1 KCFLAGS="-pipe -mcpu=cortex-a72+crc"  LOCALVERSION=-clang12a CC=clang-12 LD=ld.lld-12 AR=llvm-ar-12 NM=llvm-nm-12 STRIP=llvm-strip-12  OBJCOPY=llvm-objcopy-12 OBJDUMP=llvm-objdump-12 READELF=llvm-readelf-12  HOSTCC=clang-12 HOSTCXX=clang++-12 CXX=clang++-12 HOSTAR=llvm-ar-12 HOSTLD=ld.lld-12 bindeb-pkg
#make  LLVM=1 LLVM_IAS=1 KCFLAGS="-pipe -mcpu=cortex-a72+crc"  LOCALVERSION=-clang12kasan CC=clang-12 LD=ld.lld-12 AR=llvm-ar-12 NM=llvm-nm-12 STRIP=llvm-strip-12  OBJCOPY=llvm-objcopy-12 OBJDUMP=llvm-objdump-12 READELF=llvm-readelf-12  HOSTCC=clang-12 HOSTCXX=clang++-12 CXX=clang++-12 HOSTAR=llvm-ar-12 HOSTLD=ld.lld-12 oldconfig
#make  LLVM=1 LLVM_IAS=1 KCFLAGS="-pipe -mcpu=cortex-a72+crc"  LOCALVERSION=-clang12kasan CC=clang-12 LD=ld.lld-12 AR=llvm-ar-12 NM=llvm-nm-12 STRIP=llvm-strip-12  OBJCOPY=llvm-objcopy-12 OBJDUMP=llvm-objdump-12 READELF=llvm-readelf-12  HOSTCC=clang-12 HOSTCXX=clang++-12 CXX=clang++-12 HOSTAR=llvm-ar-12 HOSTLD=ld.lld-12 menuconfig
cp -f .config /root/last-build-config-${KVAR}.txt

exit 0

#ld.lld-12: error: Never resolved function from blockaddress (Producer: 'LLVM12.0.1' Reader: 'LLVM 12.0.1')
#make[4]: *** [scripts/Makefile.modpost:134: fs/xfs/xfs.lto.o] Error 1
