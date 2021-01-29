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

# The following patch is from
# https://lists.freedesktop.org/archives/dri-devel/2021-January/295094.html
# https://lists.freedesktop.org/archives/dri-devel/2021-January/295093.html
patch -p0 <<'EOF'
--- drivers/gpu/drm/vc4/vc4_hvs.c.~1~	2021-01-20 02:27:34.000000000 +0900
+++ drivers/gpu/drm/vc4/vc4_hvs.c	2021-01-22 09:44:19.046947797 +0900
@@ -618,11 +618,11 @@
 	 * for now we just allocate globally.
 	 */
 	if (!hvs->hvs5)
-		/* 96kB */
-		drm_mm_init(&hvs->lbm_mm, 0, 96 * 1024);
+		/* 48k words of 2x12-bit pixels */
+		drm_mm_init(&hvs->lbm_mm, 0, 48 * 1024);
 	else
-		/* 70k words */
-		drm_mm_init(&hvs->lbm_mm, 0, 70 * 2 * 1024);
+		/* 60k words of 4x12-bit pixels */
+		drm_mm_init(&hvs->lbm_mm, 0, 60 * 1024);
 
 	/* Upload filter kernels.  We only have the one for now, so we
 	 * keep it around for the lifetime of the driver.
--- drivers/gpu/drm/vc4/vc4_plane.c.~1~	2021-01-20 02:27:34.000000000 +0900
+++ drivers/gpu/drm/vc4/vc4_plane.c	2021-01-22 09:44:48.527952460 +0900
@@ -437,6 +437,7 @@
 static u32 vc4_lbm_size(struct drm_plane_state *state)
 {
 	struct vc4_plane_state *vc4_state = to_vc4_plane_state(state);
+	struct vc4_dev *vc4 = to_vc4_dev(state->plane->dev);
 	u32 pix_per_line;
 	u32 lbm;
 
@@ -472,7 +473,11 @@
 		lbm = pix_per_line * 16;
 	}
 
-	lbm = roundup(lbm, 32);
+	/* Align it to 64 or 128 (hvs5) bytes */
+	lbm = roundup(lbm, vc4->hvs->hvs5 ? 128 : 64);
+
+	/* Each "word" of the LBM memory contains 2 or 4 (hvs5) pixels */
+	lbm /= vc4->hvs->hvs5 ? 4 : 2;
 
 	return lbm;
 }
@@ -912,9 +917,9 @@
 		if (!vc4_state->is_unity) {
 			vc4_dlist_write(vc4_state,
 					VC4_SET_FIELD(vc4_state->crtc_w,
-						      SCALER_POS1_SCL_WIDTH) |
+						      SCALER5_POS1_SCL_WIDTH) |
 					VC4_SET_FIELD(vc4_state->crtc_h,
-						      SCALER_POS1_SCL_HEIGHT));
+						      SCALER5_POS1_SCL_HEIGHT));
 		}
 
 		/* Position Word 2: Source Image Size */
EOF

xzcat /usr/src/linux-config-5.10/config.arm64_none_arm64.xz >.config
cat >>.config <<'EOF'
CONFIG_LOCALVERSION="-vc4patched"
CONFIG_RESET_RASPBERRYPI=m
CONFIG_ARM_RASPBERRYPI_CPUFREQ=m
CONFIG_SENSORS_RASPBERRYPI_HWMON=m
CONFIG_CC_OPTIMIZE_FOR_SIZE=y
CONFIG_MQ_IOSCHED_KYBER=y
CONFIG_IOSCHED_BFQ=y
CONFIG_DRM_VC4=m
CONFIG_DRM_VC4_HDMI_CEC=y
CONFIG_VDPA=m
CONFIG_NTFS_FS=m
CONFIG_IKCONFIG=m
CONFIG_IKCONFIG_PROC=y
CONFIG_DEBUG_INFO=n
EOF
make oldconfig
nice -19 make -j 12 bindeb-pkg

if ! fgrep -q reset /etc/initramfs-tools/modules /usr/share/initramfs-tools/modules.d/*; then
  echo "reset_raspberrypi" >>/etc/initramfs-tools/modules
  echo 'reset_raspberrypi is added to /etc/initramfs-tools/modules.'
fi

#CONFIG_ARCH_BCM_IPROC=y
#CONFIG_ARCH_BRCMSTB=y
#CONFIG_ARCH_BCM4908=y
