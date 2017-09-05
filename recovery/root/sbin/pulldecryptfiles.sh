#!/sbin/sh

# This pulls the files out of /vendor that are needed for decrypt
# This allows us to decrypt the device in recovery and still be
# able to unmount /vendor when we are done.

SLOT=$(getprop ro.boot.slot_suffix)


if [ "`mount|grep "/dev/block/bootdevice/by-name/system${SLOT} on /system_root"`" == "" ];then
        mount -o rw,remount rootfs /
        mkdir /system_root
        mount -t ext4 -o ro /dev/block/bootdevice/by-name/system$SLOT /system_root
else    
        exit
fi

if [ "`mount|grep "/dev/block/bootdevice/by-name/system${SLOT} on /system "`" == "" ];then
	mkdir -p /system
        mount -o bind /system_root/system /system
	mkdir /tmp/system
	cp -r /system/lib64 /tmp/system/
	cp -r /system/bin /tmp/system/
	umount /system
	umount /system_root
	mkdir /system/lib64
	mkdir /system/bin
	mv /tmp/system/lib64/* /system/lib64/ >> /tmp/mv.log 2>&1
	mv /tmp/system/bin/* /system/bin/ >> /tmp/mv.log 2>&1
	rmdir /tmp/system/lib64 /tmp/system/bin /tmp/system
fi

if [ "`mount|grep "/dev/block/bootdevice/by-name/userdata on /data"`" == "" ];then
        cp -a /system/lib64/libext2fs.so /sbin/libext2fs.so
        cp -a /system/lib64/libext2_quota.so /sbin/libext2_quota.so
        cp -a /system/lib64/libext2_uuid.so /sbin/libext2_uuid.so
        cp -a /system/lib64/libext2_blkid.so /sbin/libext2_blkid.so
        cp -a /system/lib64/libext2_e2p.so /sbin/libext2_e2p.so
        cp -a /system/lib64/libext2_com_err.so /sbin/libext2_com_err.so
        cp -a /system/lib64/libsparse.so /sbin/libsparse.so
        cp -a /system/lib64/libext2_com_err.so /sbin/libext2_com_err.so
        cp -a /system/lib64/libext2_uuid.so /sbin/libext2_uuid.so

	LD_LIBRARY_PATH=/system/lib64 /system/bin/e2fsck  -y -E journal_only /dev/block/bootdevice/by-name/userdata >> /tmp/tune.log 2>&1
        LD_LIBRARY_PATH=/system/lib64 /system/bin/tune2fs -Q ^usrquota,^grpquota,^prjquota /dev/block/bootdevice/by-name/userdata >> /tmp/tune.log 2>&1
        mount /dev/block/bootdevice/by-name/userdata /data
fi

if [ "`mount|grep "/dev/block/bootdevice/by-name/vendor${SLOT} on /vendor"`" == "" ];then
	mkdir -p /vendor
	mkdir -p /tmp/vendor
        mount -t ext4 -o ro /dev/block/bootdevice/by-name/vendor_a /vendor

	cp -r /vendor/lib64 /tmp/vendor/
	cp -r /vendor/bin /tmp/vendor/

        cp /vendor/lib64/libQSEEComAPI.so /sbin/libQSEEComAPI.so
        cp /vendor/bin/qseecomd /sbin/qseecomd
	cp /vendor/lib64/hw/keystore.msm8996.so /sbin/keystore.msm8996.so
	cp /vendor/lib64/libdrmfs.so /sbin/libdrmfs.so
	cp /vendor/lib64/libdrmtime.so /sbin/libdrmtime.so
	cp /vendor/lib64/librpmb.so /sbin/librpmb.so
	cp /vendor/lib64/libssd.so /sbin/libssd.so
	cp /vendor/lib64/libdiag.so /sbin/libdiag.so
	cp /vendor/lib64/libkmcrypto.so /sbin/libkmcrypto.so
	cp /vendor/lib64/hw/gatekeeper.msm8996.so /sbin/gatekeeper.msm8996.so

	umount /vendor

	mv /tmp/vendor/* /vendor/
	rmdir /tmp/vendor
fi

setprop pulldecryptfiles.finished 1
exit 0
