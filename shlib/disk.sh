#!/bin/bash

DISK_ETAB_FILE='/var/lib/nfs/etab'
DISK_LSSCSI='/usr/bin/lsscsi'
DISK_BLKID='/sbin/blkid'
DISK_DEVKIT_DISKS='/usr/bin/devkit-disks'
DISK_UDEVADM='/sbin/udevadm'

if [ ! -x "$DISK_LSSCSI" ]; then
	echo "lsscsi not installed."
	DISK_LSSCSI=''
fi
if [ ! -f "$DISK_ETAB_FILE" ]; then
	echo "nfs export tab $DISK_ETAB_FILE not found."
	DISK_ETAB_FILE=''
fi
if [ ! -x "$DISK_BLKID" ]; then
	echo "blkid not installed."
	DISK_BLKID=''
fi
if [ ! -x "$DISK_DEVKIT_DISKS" ]; then
	echo "devkit-disks not installed."
	DISK_DEVKIT_DISKS=''
fi
if [ ! -x "$DISK_UDEVADM" ]; then
	echo "udevadm not installed."
	DISK_UDEVADM=''
fi


function isRoot() {
	if [ $EUID -eq 0 ]; then
		return 0
	else
		return 1
	fi
}

function getMounted() {
	local deviceq=`echo "$1" | sed 's@/@\\\\/@g'`
	#MNT_INFO=$(mount | awk -v mnt=$MNT_POINT '{ if ($3 == mnt) print $0 }')
	mount | awk "/^$deviceq[0-9]*/ { if(\$4 == \"type\") { print \$3 } else { print \$3, \$4 } }"
}

function isMountedDirectory() {
	local mountpoint="$1"
	mount | awk -v mnt="$mountpoint" "{ if (\$3 == mnt) print \$1 }"
}

function getDeviceFromMountPoint() {
	local mountpoint="$1"
	/bin/df -P "$mountpoint" | awk "/^\\// { print \$1 }"
}

function isDirectoryMounted() {
	[ ! -d "$1" ] && return 0
	local mountdirq=`echo "$1" | sed 's@/@\\\\/@g'`
	msg=`mount 2>&1 | awk "/^$mountdirq/ { print \$3 }"`
	if [ -z "$msg" ]; then
		return 0
	else
		return 1
	fi
}

function getMajorBlockDevice() {
	local devname="$1"
	echo "$1" | sed -r 's@[0-9]+$@@'
}

function directoryMount() {
	local dir="$1"
	if [ -d "$dir" ]; then
		msg=`isRoot && mount "$dir" 2>&1`
		if [ $? -eq 0 ]; then
			log "mount $dir"
		else
			err "failed to mount $dir"
		fi
	else
		err "failed to mount $dir"
	fi
}

function directoryUmount() {
	local dir="$1"
	isDirectoryMounted "$dir"
	if [ $? -ne 0 ]; then
		msg=`isRoot && umount "$dir" 2>&1`
		if [ $? -eq 0 ]; then
			log "umount $dir"
		else
			err "failed to umount $dir"
		fi
	else
		err "failed to umount $dir"
	fi
}

function getExports() {
	local mountdirq=`echo "$1" | sed 's@/@\\\\/@g'`
	cat $DISK_ETAB_FILE | awk "/^$mountdirq/ { print \$1 }"
}

function getExportOptions() {
	local mountdirq=`echo "$1" | sed 's@/@\\\\/@g'`
	cat $DISK_ETAB_FILE | awk "/^$mountdirq/ { split(\$2,a,\"(\"); print substr(a[2],0,length(a[2])-1) }"
}

function getExportPerms() {
	local mountdirq=`echo "$1" | sed 's@/@\\\\/@g'`
	cat $DISK_ETAB_FILE | awk "/^$mountdirq/ { split(\$2,a,\"(\"); print a[1] }"
}

function getSCSIId() {
	[ -z "$DISK_LSSCSI" ] && return


	if [ -z "$1" ]; then
		$DISK_LSSCSI | awk '/disk/ { split(substr($1, 2, 7),a,":"); print a[1] ":" a[2] ":" a[3] ":" a[4] }'
	else
		local deviceq=`echo "$1" | sed 's@/@\\\\/@g'`
		$DISK_LSSCSI | awk "/$deviceq/ { split(substr(\$1, 2, 7),a,\":\"); print a[1] \":\" a[2] \":\" a[3] \":\" a[4] }"
	fi
}

function getSCSIVendor() {
	[ -z "$DISK_LSSCSI" ] && return
	local deviceq=`echo "$1" | sed 's@/@\\\\/@g'`
	$DISK_LSSCSI | awk "/$deviceq/" | sed -r -e 's@^.{30}@@g' -e 's/  .*//g'
}

function getSCSIName() {
	[ -z "$DISK_LSSCSI" ] && return
	local scsi_host_id="$1"
	$DISK_LSSCSI -t "$scsi_host_id" | awk '/disk/ { printf "%s", $3; }'
}

function getSCSIHosts() {
	[ -z "$DISK_LSSCSI" ] && return
	if [ ! -z "$1" ]; then
		local hostq=`echo "$1" | sed 's@/@\\\\/@g'`
		$DISK_LSSCSI -H | awk "/\[$hostq\]/ { print substr(\$1, 2, length(\$1)-2) }"
	else
		$DISK_LSSCSI -H | awk "/\[[0-9]+\]/ { print substr(\$1, 2, length(\$1)-2) }"
	fi
}

function getOccupiedSCSIHosts() {
	[ -z "$DISK_LSSCSI" ] && return
	$DISK_LSSCSI | awk "{ split(substr(\$1, 2, 7),a,\":\"); print a[1] }"
}

function rescanEmptySCSIHosts() {
	scsi_host_ids=`getSCSIHosts "$1"`
	occupied_scsi_host_ids=`getOccupiedSCSIHosts`
	for host_id in $scsi_host_ids; do
		found=0
		for occid in $occupied_scsi_host_ids; do
			if [ "$occid" == "$host_id" ]; then
				found=1
				break
			fi
		done

		if [ $found -eq 0 ]; then
			rescanSCSIHost "$host_id"
		fi
	done

	now_occupied_scsi_host_ids=`getOccupiedSCSIHosts`
	newdevices=0
	for host_id in $now_occupied_scsi_host_ids; do
		found=0
		for occid in $occupied_scsi_host_ids; do
			if [ "$occid" == "$host_id" ]; then
				found=1
				break
			fi
		done

		if [ $found -eq 0 ]; then
			if [ $newdevices -eq 0 ]; then
				sleep 1
				devname=`getSCSIName "$host_id"`
				echo -n "$devname"
			else
				devname=`getSCSIName "$host_id"`
				echo -n " $devname"	
			fi
			newdevices=$[$newdevices + 1]
		fi
	done
}

function rescanSCSIHost() {
	local msg
	msg=`echo "scsi add-single-device $1" > "/proc/scsi/scsi" 2>&1`
}

function ejectSCSIDevice() {
	local msg
	local hcil=`echo "$1" | awk '{split($0,a,":"); print a[1], a[2], a[3], a[4]}'`
	msg=`echo "scsi remove-single-device $hcil" > "/proc/scsi/scsi" 2>&1`
}

function ejectSCSIDeviceByDevName() {
	local msg
	local scsi_host_id=`getSCSIId "$1"`
	local hcil=`echo "$scsi_host_id" | awk '{split($0,a,":"); print a[1], a[2], a[3], a[4]}'`

	[ -z "$hcil" ] && return 1
	msg=`echo "scsi remove-single-device $hcil" > "/proc/scsi/scsi" 2>&1`
	return 0
}

function getUDevInfo() {
	[ -z "$DISK_UDEVADM" ] && return
	$DISK_UDEVADM info -a -p  $(udevadm info -q path -n "$1")
}

function getDevkitInfo() {
	[ -z "$DISK_DEVKIT_DISKS" ] && return
	$DISK_DEVKIT_DISKS --show-info "$1"
}

function getVolumeLebel() {
	[ -z "$DISK_DEVKIT_DISKS" ] && return
	$DISK_DEVKIT_DISKS --show-info "$1" | sed -r 's@^ *([A-Za-z_\ \-]+)\: *(\w+)@\1=\2@' | grep 'label='
}

function getVolumeInfo() {
	[ -z "$DISK_BLKID" ] && return
	local qq=`echo "$2" | sed 's@/@\\\\/@g'`
	$DISK_BLKID "$1" -o udev | awk -F '=' "/$qq/ { print \$2 }"
}

function hasFstabEntry() {
	local device="$1"
	local label="$2"
	local uuid="$3"
	local ret=0
	local msg=`cat /etc/fstab | grep "^$device"`
	if [ ! -z "$msg" ]; then
		log "found fstab for $device"
		ret=1
	else
		msg=`cat /etc/fstab | grep "^LABEL=$label"`
		if [ ! -z "$msg" ]; then
			log "found fstab for $label"
			ret=1
		else
			msg=`cat /etc/fstab | grep "^UUID=$uuid"`
			if [ ! -z "$msg" ]; then
				log "found fstab for $uuid"
				ret=1
			fi
		fi
	fi
	return $ret
}

function addFstabEntryForDevice() {
	[ -z "$DISK_LSSCSI" ] && return

	local DEVNAME="$1"
	local mountdir="$2"
	scsi_disk_ids=`getSCSIId "$DEVNAME"`
	log "add fstab entry for devices: $DEVNAME"
	log "add fstab entry for devices: $scsi_disk_ids"

	for id in $scsi_disk_ids; do
		disk_info=``
		devname=`getSCSIName "$id"`

		log "add fstab entry for device $devname"

		base=`basename $devname`
		
		for part in /sys/block/$base/$base*; do
			local partdevname='/dev/'`basename $part`
			local partlabel=`getVolumeInfo "$partdevname" ID_FS_LABEL_ENC`
			local partuuid=`getVolumeInfo "$partdevname" ID_FS_UUID_ENC`
			if [ ! -z "$partlabel" ]; then
				partmountdir="$mountdir/$partlabel"
			else
				partmountdir="$mountdir/`basename $part`"
			fi
			local partmountopts='noauto'
			local parttype='auto'
			local partdump='0'
			local partpass='0'
			log "prepare partition $partdevname (label=$partlabel, uuid=$partuuid)"
			hasFstabEntry $partdevname $partlabel $partuuid
			if [ $? -eq 0 ]; then
				log "no fstab entry found for $partdevname"
				log "create mount directory $partmountdir"
				if [ ! -d "$partmountdir" ]; then
					msg=`mkdir -p "$partmountdir" 2>&1`
					[ $? -ne 0 ] && err "failed to create $partmountdir for $partdevname"
				fi
				if [ ! -z "$partuuid" ]; then
					partmountline="UUID=$partuuid  $partmountdir  $parttype  $partmountopts  $partdump  $partpass"
				elif [ ! -z "$partlabel" ]; then 
					partmountline="LABEL=$partlabel  $partmountdir  $parttype  $partmountopts  $partdump  $partpass"
				else
					partmountline="$partdevname  $partmountdir  $parttype  $partmountopts  $partdump  $partpass"
				fi
				log "add fstab entry $partmountline"
				msg=`echo "$partmountline" 2>&1 >> /etc/fstab`
				if [ $? -ne 0 ]; then
					err "failed to add fstab entry \"$partmountline\" for $partdevname"
				fi
			fi
		done
	done
}

function getDeviceSMARTInfo() {
	[ -z "$DISK_DEVKIT_DISKS" ] && return

	local device="$1"
	"$DISK_DEVKIT_DISKS" --show-info "$device" | awk 'BEGIN{o=0} /=====/ { o=1 } { if (o!=0) print $0 }'
}
