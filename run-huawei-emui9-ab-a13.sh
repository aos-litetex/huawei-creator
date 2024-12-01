#!/bin/bash

#Usage:
#sudo bash run-huawei-ab-a13.sh  [/path/to/system.img] [version] [model device] [huawei animation]
#cleanups
#A13 version
umount d

set -ex

origin="$(readlink -f -- "$0")"
origin="$(dirname "$origin")"


targetArch=64
srcFile="$1"
versionNumber="$2"
model="$3"
bootanim="$4"
erofs="$5"

if [ ! -f "$srcFile" ];then
	echo "Usage: sudo bash run-huawei-ab-a13.sh [/path/to/system.img] [version] [model device] [bootanimation] [erofs]"
	echo "version=LeaOS A13"
	echo "device=ANE-LX1"
	echo "bootanimation=[Y/N]"
	echo "erofs=[Y/N]"
	exit 1
fi

"$origin"/simg2img "$srcFile" s-ab-raw.img || cp "$srcFile" s-ab-raw.img

rm -Rf tmp
mkdir -p d tmp
e2fsck -y -f s-ab-raw.img
resize2fs s-ab-raw.img 5000M
e2fsck -E unshare_blocks -y -f s-ab-raw.img
mount -o loop,rw s-ab-raw.img d
(
	#----------------------------- Missing Huawei root folder -----------------------------------------------------		
	cd d
	
	rm -rf splash2
	rm -rf modem_log
	rm -rf preavs
	
	mkdir splash2
	chown root:root splash2
	chmod 777 splash2
	xattr -w security.selinux u:object_r:rootfs:s0 splash2
	
	mkdir modem_log
	chown root:root modem_log
	chmod 777 modem_log
	xattr -w security.selinux u:object_r:rootfs:s0 modem_log
	
	mkdir preavs
	chown root:root preavs
	chmod 777 preavs
	xattr -w security.selinux u:object_r:rootfs:s0 preavs

	cd system
		
		
	#---------------------------------Setting properties -------------------------------------------------
	
	echo "#" >> build.prop
	echo "## Adding kirin props" >> build.prop
	echo "#" >> build.prop
	
	sed -i "/ro.system.build.type/d" build.prop 
	sed -i "/ro.build.type/d" build.prop 	
	
	echo "ro.system.build.type=user" >> build.prop
	echo "ro.build.type=user" >> build.prop

	
	# change product
	sed -i "/ro.product.manufacturer/d" build.prop
	sed -i "/ro.product.model/d" build.prop
	sed -i "/ro.product.name/d" build.prop
	sed -i "/ro.product.brand/d" build.prop
	sed -i "/ro.product.device/d" build.prop
		
	echo "ro.product.manufacturer=HUAWEI" >> build.prop
	echo "ro.product.model=$model" >> build.prop
	echo "ro.product.name=$model" >> build.prop
	

	# change product.system
	sed -i "/ro.product.system.model/d" build.prop 
	sed -i "/ro.product.system.brand/d" build.prop 
	sed -i "/ro.product.system.device/d" build.prop 
	sed -i "/ro.product.system.name/d" build.prop 
	
	echo "ro.product.system.model=$model" >>  build.prop
	echo "ro.product.system.name=$model" >>  build.prop
		
	# change product.product
	sed -i "/ro.product.product.model/d" product/etc/build.prop 
	sed -i "/ro.product.product.brand/d" product/etc/build.prop 
	sed -i "/ro.product.product.device/d" product/etc/build.prop 
	sed -i "/ro.product.product.name/d" product/etc/build.prop
	echo "ro.product.product.model=$model" >> product/etc/build.prop
	echo "ro.product.product.name=$model" >> product/etc/build.prop

	
	# change product.system_ext
	sed -i "/ro.product.system_ext.model/d" system_ext/etc/build.prop 
	sed -i "/ro.product.system_ext.brand/d" system_ext/etc/build.prop 
	sed -i "/ro.product.system_ext.device/d" system_ext/etc/build.prop 
	sed -i "/ro.product.system_ext.name/d" system_ext/etc/build.prop
	echo "ro.product.system_ext.model=$model" >> system_ext/etc/build.prop
	echo "ro.product.system_ext.name=$model" >> system_ext/etc/build.prop
	

	# set lineage version number for lineage build    	
	sed -i "/ro.lineage.version/d" build.prop
	sed -i "/ro.lineage.display.version/d" build.prop
	sed -i "/ro.modversion/d" build.prop
	sed -i "/ro.lineage.device/d" build.prop
	echo "ro.lineage.version=20" >>  build.prop
	echo "ro.lineage.display.version=$versionNumber" >>  build.prop
	
	# set modversion
	echo "ro.modversion=$versionNumber" >>  build.prop

		
	# set default sound
	echo "ro.config.ringtone=Ring_Synth_04.ogg" >>  build.prop
	echo "ro.config.notification_sound=OnTheHunt.ogg">>  build.prop
	echo "ro.config.alarm_alert=Argon.ogg">>  build.prop

 
	# Debug LMK - for Android Kernel that support it - e
	echo "ro.lmk.debug=false" >>  build.prop
	
	# Debug Huawei Off/On - if on EMUI8 start service logcat on boot
	echo "persist.sys.hiview.debug=0" >> build.prop
	echo "persist.sys.huawei.debug.on=0" >> build.prop

	
	# Enable wireless display (Cast/Miracast)
	echo "persist.debug.wfd.enable=1" >>  build.prop
	
	# Audio
	echo "audio.deep_buffer.media=true" >>  build.prop
	echo "audio.offload.buffer.size.kb=32" >> build.prop
	echo "ro.audio.offload_wakelock=false" >> build.prop
	
	# Display
	echo "ro.surface_flinger.running_without_sync_framework=true" >>  build.prop

	# Graphics hi6250 ?
	echo "debug.egl.hw=1" >>  build.prop
	echo "debug.egl.profiler=1" >>  build.prop
	echo "debug.hwui.use_buffer_age=false" >>  build.prop
	echo "debug.performance.tuning=1" >>  build.prop
	echo "debug.sf.enable_hwc_vds=0" >>  build.prop
	echo "debug.sf.hw=1" >>  build.prop
	echo "hwui.disable_vsync=true" >>  build.prop
	echo "ro.config.enable.hw_accel=true" >>  build.prop
	echo "video.accelerate.hw=1" >>  build.prop
	echo "ro.surface_flinger.max_frame_buffer_acquired_buffers=3" >> build.prop
	echo "debug.cpurend.vsync=false" >> build.prop
	echo "ro.hardware.egl=mali" >> build.prop
	echo "ro.hardware.vulkan=mali" >> build.prop
	echo "debug.sf.disable_backpressure=1" >>  build.prop
	echo "debug.sf.latch_unsignaled=1" >>  build.prop

	# Color
	echo "persist.sys.sf.native_mode=1" >> build.prop
	echo "persist.sys.sf.color_mode=1" >> build.prop
	echo "persist.sys.sf.color_saturation=1.1" >> build.prop
	
	# CPU
	echo "persist.sys.boost.byeachfling=true" >> build.prop
	echo "persist.sys.boost.skipframe=3" >> build.prop
	echo "persist.sys.boost.durationms=1000" >> build.prop		
	echo "persist.sys.cpuset.enable=1" >> build.prop
	echo "persist.sys.performance=true" >> build.prop
	
	# bluetooth
	echo "bluetooth.enable_timeout_ms=12000" >> build.prop
	echo "persist.sys.bt.esco_transport_unit_size=16" >> build.prop
	
	# Usb
	echo "persist.sys.usb.config=hisuite,mtp,mass_storage" >> build.prop 
	
	
	# Performance android 13
	echo "debug.performance.tuning=1" >> build.prop
	

	#-----------------------------File copy -----------------------------------------------------

	# Copy bootanimation.zip	
	if [ "$bootanim" == "Y" ];then
		mkdir media
		chmod 777 media
		chown root:root media
		xattr -w security.selinux u:object_r:system_file:s0 media
		
		cp "$origin/files-patch/media/bootanimation.zip" "media/bootanimation.zip"
		chmod 644 "media/bootanimation.zip"
		xattr -w security.selinux u:object_r:system_file:s0 "media/bootanimation.zip"
	fi

	# ANE-LX1 Huawei P20 Lite
	if [ "$model" == "ANE-LX1" ];then
		# NFC 
		cp "$origin/files-patch/system/etc/NFC/libnfc_brcm_anne.conf" etc/libnfc-brcm.conf
		xattr -w security.selinux u:object_r:system_file:s0  etc/libnfc-brcm.conf
		cp "$origin/files-patch/system/etc/NFC/libnfc_nci_anne.conf" etc/libnfc-nci.conf
		xattr -w security.selinux u:object_r:system_file:s0 etc/libnfc-nci.conf
		cp "$origin/files-patch/system/etc/NFC/libnfc_nxp_anne.conf" etc/libnfc-nxp.conf
		xattr -w security.selinux u:object_r:system_file:s0 etc/libnfc-nxp.conf
		cp "$origin/files-patch/system/etc/NFC/libnfc_nxp_RF_anne.conf" etc/libnfc-nxp_RF.conf
		xattr -w security.selinux u:object_r:system_file:s0 etc/libnfc-nxp_RF.conf
		
		cp "$origin/files-patch/system/etc/NFC/libnfc_brcm_anne.conf" product/etc/libnfc-brcm.conf
		xattr -w security.selinux u:object_r:system_file:s0  product/etc/libnfc-brcm.conf
		cp "$origin/files-patch/system/etc/NFC/libnfc_nci_anne.conf" product/etc/libnfc-nci.conf
		xattr -w security.selinux u:object_r:system_file:s0 product/etc/libnfc-nci.conf
		cp "$origin/files-patch/system/etc/NFC/libnfc_nxp_anne.conf" product/etc/libnfc-nxp.conf
		xattr -w security.selinux u:object_r:system_file:s0 product/etc/libnfc-nxp.conf
		cp "$origin/files-patch/system/etc/NFC/libnfc_nxp_RF_anne.conf" product/etc/libnfc-nxp_RF.conf
		xattr -w security.selinux u:object_r:system_file:s0 product/etc/libnfc-nxp_RF.conf

		echo "ro.product.system.device=HWANE" >>  build.prop
		echo "ro.product.system.brand=HUAWEI" >>  build.prop	
		echo "ro.product.brand=HUAWEI" >> build.prop
		echo "ro.product.device=HWANE" >> build.prop
		echo "ro.product.product.device=HWANE" >>  product/etc/build.prop
		echo "ro.product.product.brand=HUAWEI" >>  product/etc/build.prop	
		echo "ro.product.system_ext.device=HWANE" >>  system_ext/etc/build.prop
		echo "ro.product.system_ext.brand=HUAWEI" >>  system_ext/etc/build.prop
		echo "ro.build.product=ANE" >> build.prop
		echo "ro.lineage.device=HWANE" >>  build.prop
				
		# From iceows supl20 apk (# Hisi)
		echo "is_hisi_connectivity_chip=1" >> build.prop
		echo "ro.hardware.consumerir=hisi.hi6250" >> build.prop		
		echo "ro.hardware.hisupl=hi1102"  >> build.prop;
		
		# For FM Radio volume (# Hisi)
		echo "ro.connectivity.chiptype=hisi"  >> build.prop;
	fi	
	
	
	# Remove duplicate media audio
	rm -rf product/media/audio/ringtones/ANDROMEDA.ogg
	rm -rf product/media/audio/ringtones/CANISMAJOR.ogg
	rm -rf product/media/audio/ringtones/URSAMINOR.ogg
	
	# Remove non huawei Overlay
	rm -rf product/overlay/treble-overlay-infinix-*
	rm -rf product/overlay/treble-overlay-lenovo-*
	rm -rf product/overlay/treble-overlay-lge-*
	rm -rf product/overlay/treble-overlay-asus-*
	rm -rf product/overlay/treble-overlay-xiaomi-*
	rm -rf product/overlay/treble-overlay-samsung-*
	rm -rf product/overlay/treble-overlay-sony-*	
	rm -rf product/overlay/treble-overlay-tecno-*
	rm -rf product/overlay/treble-overlay-realme-*
	rm -rf product/overlay/treble-overlay-oppo-*
	rm -rf product/overlay/treble-overlay-nokia-*
	rm -rf product/overlay/treble-overlay-oneplus-*	
	rm -rf product/overlay/treble-overlay-nubia-*		
	rm -rf product/overlay/treble-overlay-moto-*	
	rm -rf product/overlay/treble-overlay-lg-*
	rm -rf product/overlay/treble-overlay-htc-*
	rm -rf product/overlay/treble-overlay-blackview-*
	rm -rf product/overlay/treble-overlay-vivo-*
	rm -rf product/overlay/treble-overlay-vsmart-*
	rm -rf product/overlay/treble-overlay-razer-*
	rm -rf product/overlay/treble-overlay-sharp-*
	

	# Tee Deamon
	cp "$origin/files-patch/system/bin/tee_auth_daemon" bin/tee_auth_daemon
	xattr -w security.selinux u:object_r:teecd_auth_exec:s0  bin/tee_auth_daemon
	chmod 755 bin/tee_auth_daemon
	# 2000 = shell
	chown root:2000 bin/tee_auth_daemon
	cp "$origin/files-patch/system/bin/79b77788-9789-4a7a-a2be-b60155eef5f4.sec" bin/79b77788-9789-4a7a-a2be-b60155eef5f4.sec
	xattr -w security.selinux u:object_r:system_file:s0  bin/79b77788-9789-4a7a-a2be-b60155eef5f4.sec
	cp "$origin/files-patch/system/lib64/libc_secshared.so" lib64/libc_secshared.so
	xattr -w security.selinux u:object_r:system_lib_file:s0  lib64/libc_secshared.so
	cp "$origin/files-patch/system/lib64/libtuidaemon.so" lib64/libtuidaemon.so
	xattr -w security.selinux u:object_r:system_lib_file:s0  lib64/libtuidaemon.so
	cp "$origin/files-patch/system/lib64/libteec_client.so" lib64/libteec_client.so
	xattr -w security.selinux u:object_r:system_lib_file:s0  lib64/libteec_client.so
	cp "$origin/files-patch/system/lib64/libhidlbase.so" lib64/libhidlbase.so
	xattr -w security.selinux u:object_r:system_lib_file:s0  lib64/libhidlbase.so
	cp "$origin/files-patch/system/lib64/vendor.huawei.hardware.libteec@1.0.so" lib64/vendor.huawei.hardware.libteec@1.0.so
	xattr -w security.selinux u:object_r:system_lib_file:s0  lib64/vendor.huawei.hardware.libteec@1.0.so
	cp "$origin/files-patch/system/lib64/vendor.huawei.hardware.libteec@2.0.so" lib64/vendor.huawei.hardware.libteec@2.0.so
	xattr -w security.selinux u:object_r:system_lib_file:s0   lib64/vendor.huawei.hardware.libteec@2.0.so	

	
	# Codec bluetooth 32 bits
	cp "$origin/files-patch/system/lib/libaptX_encoder.so" lib/libaptX_encoder.so
	xattr -w security.selinux u:object_r:system_lib_file:s0 lib/libaptX_encoder.so
	cp "$origin/files-patch/system/lib/libaptXHD_encoder.so" lib/libaptXHD_encoder.so
	xattr -w security.selinux u:object_r:system_lib_file:s0 lib/libaptXHD_encoder.so
	
	# Codec bluetooth 64 bits
	cp "$origin/files-patch/system/lib64/libaptX_encoder.so" lib64/libaptX_encoder.so
	xattr -w security.selinux u:object_r:system_lib_file:s0 lib64/libaptX_encoder.so
	cp "$origin/files-patch/system/lib64/libaptXHD_encoder.so" lib64/libaptXHD_encoder.so
	xattr -w security.selinux u:object_r:system_lib_file:s0 lib64/libaptXHD_encoder.so
	
	# Bluetooth conf : 1000 = system
	mkdir etc/bluetooth/
	chmod 766 etc/bluetooth/
	chown 1000:1000 etc/bluetooth/
	xattr -w security.selinux u:object_r:system_file:s0 etc/bluetooth
	
	cp "$origin/files-patch/system/etc/bluetooth/bt_did.conf" etc/bluetooth/bt_did.conf
	xattr -w security.selinux u:object_r:system_file:s0 etc/bluetooth/bt_did.conf
	cp "$origin/files-patch/system/etc/bluetooth/bt_stack.conf" etc/bluetooth/bt_stack.conf
	xattr -w security.selinux u:object_r:system_file:s0 etc/bluetooth/bt_stack.conf
	
	# Special linkerconfig to support preavs
	#rm -rf ../linkerconfig/ld.config.txt
	#cp "$origin/files-patch/linkerconfig/ld.config.txt" ../linkerconfig/ld.config.txt
	#xattr -w security.selinux object_r:linkerconfig_file:s0 ../linkerconfig/ld.config.txt
	#chown root:root ../linkerconfig/ld.config.txt
	#chmod 777 ../linkerconfig/ld.config.txt
	
	#cp "$origin/files-patch/linkerconfig/ld.config.28.txt" etc/ld.config.28.txt
	#cp "$origin/files-patch/linkerconfig/ld.config.28.txt" etc/ld.config.txt
	#xattr -w security.selinux u:object_r:system_file:s0 etc/ld.config.28.txt
	#xattr -w security.selinux u:object_r:system_file:s0 etc/ld.config.txt

		
	# --------------AGPS Patch Only gnss model ---------------------- #
	
	if [ "$model" == "FIG-LX1" ] || [ "$model" == "ANE-LX1" ] || [ "$model" == "POT-LX1" ];then
	
		cp "$origin/files-patch/system/bin/gnss_watchlssd_thirdparty" bin/gnss_watchlssd_thirdparty
		cp "$origin/files-patch/system/lib/libgnss_lss_gw_thirdparty.so" lib/libgnss_lss_gw_thirdparty.so
		cp "$origin/files-patch/system/lib64/libgnss_lss_gw_thirdparty.so" lib64/libgnss_lss_gw_thirdparty.so
		
		mkdir app/gnss_supl20service_hisi
		chmod 755 app/
		xattr -w security.selinux u:object_r:system_file:s0 app/gnss_supl20service_hisi
		
		cp "$origin/files-patch/system/app/gnss_supl20service_hisi/gnss_supl20service_hisi.apk" app/gnss_supl20service_hisi/gnss_supl20service_hisi.apk
		xattr -w security.selinux u:object_r:system_file:s0 app/gnss_supl20service_hisi/gnss_supl20service_hisi.apk
		
		cp "$origin/files-patch/system/etc/gps_debug.conf" etc/gps_debug.conf
		cp "$origin/files-patch/system/etc/permissions/privapp-permissions-supl.xml" etc/permissions/privapp-permissions-supl.xml
		xattr -w security.selinux u:object_r:system_file:s0  etc/permissions/privapp-permissions-supl.xml
		
		mkdir etc/gnss
		xattr -w security.selinux u:object_r:system_file:s0  etc/gnss
		mkdir etc/gnss/config
		xattr -w security.selinux u:object_r:system_file:s0  etc/gnss/config
		cp "$origin/files-patch/system/etc/gnss/config/gnss_suplconfig_hisi.xml" etc/gnss/config/gnss_suplconfig_hisi.xml
		cp "$origin/files-patch/system/etc/gnss/config/gnss_lss_config_thirdparty.bin" etc/gnss/config/gnss_lss_config_thirdparty.bin
		cp "$origin/files-patch/system/etc/gnss/config/gnss_lss_rfg_key_thirdparty.pem" etc/gnss/config/gnss_lss_rfg_key_thirdparty.pem
		cp "$origin/files-patch/system/etc/gnss/config/gnss_lss_slp_thirdparty.p12" etc/gnss/config/gnss_lss_slp_thirdparty.p12
		xattr -w security.selinux u:object_r:system_file:s0  etc/gnss/config/gnss_suplconfig_hisi.xml
		xattr -w security.selinux u:object_r:system_file:s0  etc/gnss/config/gnss_lss_config_thirdparty.bin
		xattr -w security.selinux u:object_r:system_file:s0  etc/gnss/config/gnss_lss_rfg_key_thirdparty.pem
		xattr -w security.selinux u:object_r:system_file:s0  etc/gnss/config/gnss_lss_slp_thirdparty.p12
		
		# Add RC
		cp "$origin/files-patch/system/etc/init/init-gnss.rc" etc/init/init-gnss.rc
		xattr -w security.selinux u:object_r:system_file:s0 etc/init/init-gnss.rc
		
		
		# Set owner and permissions (system:system)
		chmod 755 bin/gnss_watchlssd_thirdparty
		chown root:2000 bin/gnss_watchlssd_thirdparty

		xattr -w security.selinux u:object_r:hi110x_daemon_exec:s0 bin/gnss_watchlssd_thirdparty
		xattr -w security.selinux u:object_r:system_lib_file:s0 lib/libgnss_lss_gw_thirdparty.so
		xattr -w security.selinux u:object_r:system_lib_file:s0 lib64/libgnss_lss_gw_thirdparty.so


		# For gnss_lss
		echo "/system/bin/gnss_watchlssd_thirdparty		u:object_r:hi110x_daemon_exec:s0" >> etc/selinux/plat_file_contexts 
		echo "(allow hi110x_daemon self (fifo_file (ioctl read write create getattr setattr lock append unlink rename open)))" >> etc/selinux/plat_sepolicy.cil
		echo "(allow hi110x_daemon system_data_root_file (dir (read write)))" >> etc/selinux/plat_sepolicy.cil
		echo "(allow hi110x_daemon socket_device (dir (read write)))" >> etc/selinux/plat_sepolicy.cil

	fi
	
	
	
	# Fix system ntp_server (europe pool)
	set global ntp_server europe.pool.ntp.org

	# Allow agps an set config
	echo "persist.sys.pgps.config=1"  >> build.prop;
	echo "assisted_gps_enabled=1"  >> build.prop;

	# Uncomment to Debug GPS
	# echo "log.tag.GnssConfiguration=DEBUG" >> build.prop;
	# echo "log.tag.GnssLocationProvider=DEBUG" >> build.prop;
	# echo "log.tag.GnssManagerService=DEBUG" >> build.prop;
	# echo "log.tag.NtpTimeHelper=DEBUG" >> build.prop;
	
	# active le mode journalisation
	# echo "ro.control_privapp_permissions=log" >> build.prop;


	
	#----------------------------- SELinux rules Now include in huawei.te ------------------------------	

	
	# property
	#echo "ro.hwcamera.SlowMotionZoom  u:object_r:default_prop:s0" >> etc/selinux/plat_property_contexts
		
	# Kirin	
	echo "persist.kirin.alloc_buffer_sync=true" >> build.prop
	echo "persist.kirin.texture_cache_opt=1"  >> build.prop
	echo "persist.kirin.touch_move_opt=1"  >> build.prop
	echo "persist.kirin.touch_vsync_opt=1"  >> build.prop
	echo "persist.kirin.touchevent_opt=1"  >> build.prop
	
	echo "persist.kirin.media.usbvoice.enable=true"  >> build.prop
	echo "persist.kirin.media.usbvoice.name=USB-Audio - HUAWEI GLASS"  >> build.prop
	echo "persist.kirin.media.offload.enable=true"  >> build.prop
	echo "persist.kirin.media.hires.enable=true"  >> build.prop
	
	echo "ro.kirin.config.hw_perfgenius=true"  >> build.prop
	echo "ro.kirin.config.hw_board_ipa=true"  >> build.prop
	
	# Enable lowlatency
	echo "persist.media.lowlatency.enable=true" >> build.prop
	echo "persist.kirin.media.lowlatency.enable=true" >> build.prop

	#----------------------------- tee daemon --------------------------------------------------------	
	

	#echo "(allow init teecd_auth_exec (file (read getattr map execute open)))" >> etc/selinux/plat_sepolicy.cil

	#echo "(allow tee_multi_user_socket socket_device (dir (write add_name)))" >> etc/selinux/plat_sepolicy.cil
	#echo "(allow tee_multi_user_socket socket_device (sock_file (create setattr)))" >> etc/selinux/plat_sepolicy.cil
	
	#echo "(allow init teecd_auth_exec (file (read getattr map execute open)))" >> etc/selinux/plat_sepolicy.cil

	#echo "(allow init tee_multi_user_socket (sock_file (create setattr unlink)))" >> etc/selinux/plat_sepolicy.cil
	#echo "(allow tee_multi_user_socket tmpfs (filesystem (associate)))" >> etc/selinux/plat_sepolicy.cil

	#echo "(dontaudit teecd hal_keymaster_default (process (getattr)))" >> etc/selinux/plat_sepolicy.cil
	#echo "(dontaudit teecd hal_gatekeeper_default (process (getattr)))" >> etc/selinux/plat_sepolicy.cil


	
	#-----------------------------vndk-lite --------------------------------------------------------	

	# Remove non use apex vndk
	rm -rf "system_ext/apex/com.android.vndk.v29"
	rm -rf "system_ext/apex/com.android.vndk.v30"
	rm -rf "system_ext/apex/com.android.vndk.v31"
	rm -rf "system_ext/apex/com.android.vndk.v32"

	cd ../d


	find -name \*.capex -or -name \*.apex -type f -delete
	for vndk in 28 29;do
	    for arch in 32 64;do
		d="$origin/vendor_vndk/vndk-${vndk}-arm${arch}"
		[ ! -d "$d" ] && continue
		p=lib
		[ "$arch" = 64 ] && p=lib64
		[ ! -d system/system_ext/apex/com.android.vndk.v${vndk}/${p}/ ] && continue
		for lib in $(cd "$d"; echo *);do
		    cp "$origin/vendor_vndk/vndk-${vndk}-arm${arch}/$lib" system/system_ext/apex/com.android.vndk.v${vndk}/${p}/$lib
		    xattr -w security.selinux u:object_r:system_lib_file:s0 system/system_ext/apex/com.android.vndk.v${vndk}/${p}/$lib
		    echo $lib >> system/system_ext/apex/com.android.vndk.v${vndk}/etc/vndkcore.libraries.${vndk}.txt
		done
		sort -u system/system_ext/apex/com.android.vndk.v${vndk}/etc/vndkcore.libraries.${vndk}.txt > v
		mv -f v system/system_ext/apex/com.android.vndk.v${vndk}/etc/vndkcore.libraries.${vndk}.txt
		xattr -w security.selinux u:object_r:system_file:s0 system/system_ext/apex/com.android.vndk.v${vndk}/etc/vndkcore.libraries.${vndk}.txt

		grep -v -e libgui.so -e libft2.so system/system_ext/apex/com.android.vndk.v${vndk}/etc/vndkprivate.libraries.${vndk}.txt > v
		mv -f v system/system_ext/apex/com.android.vndk.v${vndk}/etc/vndkprivate.libraries.${vndk}.txt
		xattr -w security.selinux u:object_r:system_file:s0 system/system_ext/apex/com.android.vndk.v${vndk}/etc/vndkprivate.libraries.${vndk}.txt
	    done
	done

)

sleep 1



# --------------------- erofs-vndklite or ext4-vndklite -------------------------------------------

if [ "$erofs" == "Y" ];then
	mkfs.erofs -E legacy-compress -zlz4hc -d2 s-erofs.img d/
	umount d
else
	umount d
	e2fsck -f -y s-ab-raw.img || true
	resize2fs -M s-ab-raw.img

	mv s-ab-raw.img s-vndklite.img
	chmod -R 777 s-vndklite.img
fi
	
	





