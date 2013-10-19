#!/bin/bash

backup_config_file='/etc/default/backup'
backup_device_filesystem='ext3'
backup_multiple_devices=0
backup_default_dir=''
backup_default_restore_dir=''
backup_default_retain_time=0
backup_default_include_file_list=''
backup_default_exclude_file_list=''

# temp variables per session
backup_new_devices=''

# setup the backup environment
function backup_setup() {
	if [ -r "$backup_config_file" ]; then
		debug "load config from $backup_config_file"
		source "$backup_config_file"
		if [ ! -z "$BACKUP_DEVICE_FILESYSTEM" ]; then
			backup_device_filesystem="$BACKUP_DEVICE_FILESYSTEM"
		fi
		if [ ! -z "$BACKUP_DIR" ]; then
			backup_default_dir="$BACKUP_DIR"
		fi
		if [ ! -z "$BACKUP_RESTORE_DIR" ]; then
			backup_default_restore_dir="$BACKUP_RESTORE_DIR"
		fi
		if [ ! -z "$BACKUP_INCLUDE_FILE_LIST" ]; then
			backup_default_include_file_list="$BACKUP_INCLUDE_FILE_LIST"
		fi
		if [ ! -z "$BACKUP_EXCLUDE_FILE_LIST" ]; then
			backup_default_exclude_file_list="$BACKUP_EXCLUDE_FILE_LIST"
		fi
		if [ ! -z "$BACKUP_RETAIN_TIME" ]; then
			backup_default_retain_time="$BACKUP_RETAIN_TIME"
		fi
	fi
	debug "backup device filesystem: $backup_device_filesystem"
	debug "backup directory: $backup_default_dir"
	debug "restore directory: $backup_default_restore_dir"
	debug "include file list: $backup_default_include_file_list"
	debug "exclude file list: $backup_default_exclude_file_list"
	debug "retain time: $backup_default_retain_time"
}

function backup_prepare() {
	local backupdir="$1"
	local loaddev="$2"
	[ ! -d "$backupdir" ] && return

	# get all currently connected disk devices
	# rescan for backup devices
	backup_new_devices=`rescanEmptySCSIHosts`
	if [ -z "$backup_new_devices" ]; then
		info "no new devices detected"
	else
		info "new devices $backup_new_devices"
	fi

	if [ $backup_multiple_devices -ne 0 ]; then	
		backup_mount_devices "$backupdir"
	else
		backup_mount_device "$backupdir"
	fi
}

function backup_complete() {
	local backupdir="$1"
	local ejectdev="$2"
	[ ! -d "$backupdir" ] && return

	if [ $backup_multiple_devices -ne 0 ]; then	
		backup_umount_devices "$backupdir"
	else
		backup_umount_device "$backupdir"
	fi
	
	# done with backup, now eject loading devices
	# eject all devices with are remembered in backup_prepare
	# do not forcefully disconnect all external devices 
	# only the once used and connected for backup purposes
	for dev in $backup_new_devices; do
		backup_eject_device "$dev"
	done

	if [ $ejectdev -ne 0 ]; then
		backup_eject_directory "$backupdir"
	fi
}

function backup_mount_device() {
	local backupdir="$1"
	[ ! -d "$backupdir" ] && return
}

function backup_mount_devices() {
	local backupdir="$1"
	[ ! -d "$backupdir" ] && return

	for mnt in "$backupdir"/*; do
		directoryMount "$mnt"
	done	
}

function backup_umount_device() {
	local backupdir="$1"
	[ ! -d "$backupdir" ] && return
}

function backup_umount_devices() {
	local backupdir="$1"
	[ ! -d "$backupdir" ] && return

	for mnt in "$backupdir"/*; do
		directoryUmount "$mnt"
	done
}

function backup_eject_directory() {
	local backupdir="$1"
	[ ! -d "$backupdir" ] && return

	tmp=`isMountedDirectory "$backupdir"`
	if [ ! -z "$tmp" ]; then
		log "directory $backupdir is mounted. unmount it."
		local devices=`getDeviceFromMountPoint "$backupdir"`
		echo "$devices" | while read devname; do
			majordevname=`getMajorBlockDevice "$devname"`
			log "eject device $majordevname"
			backup_eject_device "$majordevname"
		done
	fi
	
}

function backup_eject_device() {
	local devname="$1"
	[ ! -b "$devname" ] && return

	local lasterr=0
	local mounted=`getMounted $devname`
	echo "$mounted" | while read mountdir; do

		[ "$mountdir" == '/' -o -z "$mountdir" ] && continue

		#echo "find exports for $mountdir"
		exports=`getExports $mountdir`
		
		#echo "$exports"

		for e in "$exports"; do
			[ ! -d "$e" ] && continue
			info "unexport $e"
			perms=`getExportPerms $e`
			opts=`getExportOptions $e`
			msg=`/usr/sbin/exportfs -u "${perms}:${e}"`
			if [ $? -ne 0 ]; then
				err "Failed to unexport $e for device $devname"
			fi
		done

		msg=`umount "$mountdir"`
		if [ $? -ne 0 ]; then
			lasterr=$?
			err "Failed to unmount $mountdir for device $devname"
		else
			lasterr=0
			info "unmounted $mountdir for device $devname"
		fi
		[ $lasterr -ne 0 ] && break
	done
	if [ $lasterr -eq 0 ]; then
		log "eject device $devname"
		ejectSCSIDeviceByDevName "$devname"
	fi

}

function backup_device_list() {
	local backupdir="$1"
	[ ! -d "$backupdir" ] && return
	for item in "$backupdir"/*; do
		local itemok=0
		if [ -d "$item" ]; then
			local itemname=`basename "$item" | awk "/[0-9]+/ { printf \"%04i-%02i-%02i %02i:%02i:%02i\", substr(\\\$1,1,4), substr(\\\$1,5,2), substr(\\\$1,7,2), substr(\\\$1,9,2),substr(\\\$1,11,2), substr(\\\$1,13,2); }"`
			if [ ! -z "$itemname" ]; then
				local itemdate=`date --date="$itemname" "+%s" 2>/dev/null`
				if [ ! -z "$itemdate" ]; then
					local itemdatestr=`date -d "@${itemdate}" +"%F %T" 2>/dev/null`
					echo "$itemdatestr"
					itemok=1
				fi
			fi
		fi
		if [ $itemok -eq 0 ]; then
			warn "ignored $item (no backup)"
		fi
	done
}

function backup_device_get_latest() {
	backupdir="$1"
	[ ! -d "$backupdir" ] && return
	local latest=''
	local latestdate=0
	for item in "$backupdir"/*; do
		local itemok=0
		if [ -d "$item" ]; then
			local itemname=`basename "$item" | awk "/[0-9]+/ { printf \"%04i-%02i-%02i %02i:%02i:%02i\", substr(\\\$1,1,4), substr(\\\$1,5,2), substr(\\\$1,7,2), substr(\\\$1,9,2),substr(\\\$1,11,2), substr(\\\$1,13,2); }"`
			if [ ! -z "$itemname" ]; then
				local itemdate=`date --date="$itemname" "+%s" 2>/dev/null`
				if [ ! -z "$itemdate" ]; then
					if [ $itemdate -gt $latestdate ]; then
						latest="$item"
						latestdate=$itemdate
					fi
					itemok=1
				fi
			fi
		fi
	done
	if [ $latestdate -ne 0 ]; then
		echo "$latest"
	fi
}

function backup_chown() {
	# only try to change ownership if script is executed by root
	if [ $EUID -eq 0 ]; then
		chown $*
	fi
}

function backup_device_create() {
	local backupdir="$1"
	local include_list_file="$2"
	local exclude_list_file="$3"

	debug "include list file: $include_list_file"
	debug "exclude list file: $exclude_list_file"
	
	if [ -f "$include_list_file" ]; then
		include_list=`cat "$include_list_file"`
	else
		include_list=''
	fi
	if [ -f "$exclude_list_file" ]; then
		exclude_list=`cat "$exclude_list_file"`
	else
		exclude_list=''
	fi

	itemdate=`date "+%Y%m%d%H%M%S"`
	destdir="$backupdir/$itemdate"
	msg=`mkdir -p "$destdir" 2>&1`
	if [ $? -ne 0 ]; then
		err "failed to create directory $destdir: $msg"
		return
	fi
	echo "$include_list" | while read src; do
		[ -z "$src" ] && continue

		if [ ! -z "$exclude_list" ]; then
			srcfiles=`find "$src" | grep --invert-match "$exclude_list"`
		else
			srcfiles=`find "$src"`
		fi

		echo "$srcfiles" | while read srcfile; do
			[ -z "$srcfile" ] && continue

			destfile="${destdir}${srcfile}"

			if [ ! -d "$srcfile" ]; then
				destdir_final=`dirname "$destfile"`
				[ ! -d "$destdir_final" ] && mkdir -p "$destdir_final"
				msg=`cp -d --preserve=all "$srcfile" "$destfile" 2>&1`
				RET=$?
			else 
				[ ! -d "$destfile" ] && mkdir -p "$destfile"
				msg=`chmod --reference="$srcfile" "$destfile" 2>&1 && backup_chown --reference="$srcfile" "$destfile" 2>&1`
				RET=$?
			fi

			if [ $RET -eq 0 ]; then
				log "$srcfile -> $destfile"
			else
				warn "$srcfile -> $destfile failed ($msg)"
			fi
		done
	done
}

function backup_device_restore() {
	local backupdir="$1"
	local destdir="$2"
	local include_list_file="$3"
	local exclude_list_file="$4"

	if [ -f "$include_list_file" ]; then
		include_list=`cat "$include_list_file"`
	else
		include_list=''
	fi
	if [ -f "$exclude_list_file" ]; then
		exclude_list=`cat "$exclude_list_file"`
	else
		exclude_list=''
	fi

	mkdir -p "$destdir"
	if [ ! -z "$include_list" ]; then
		if [ ! -z "$exclude_list" ]; then
			filelist=`find $backupdir | grep "$include_list" | grep --invert-match "$exclude_list"`
		else
			filelist=`find $backupdir | grep "$include_list"`
		fi
	else
		if [ ! -z "$exclude_list" ]; then
			filelist=`find $backupdir | grep --invert-match "$exclude_list"`
		else
			filelist=`find $backupdir`
		fi
	fi
	
	echo "$filelist" | while read srcfile; do
		[ -z "$srcfile" ] && continue
		[ "$srcfile" == "$backupdir" ] && continue

		if [ ! -d "$srcfile" ]; then
			destdir_final=`dirname $destfile`
			[ ! -d "$destdir_final" ] && mkdir -p "$destdir_final"
			msg=`cp -d --preserve=all "$srcfile" "$destfile" 2>&1`
			RET=$?
		else 
			[ ! -d "$destfile" ] && mkdir -p "$destfile"
			msg=`chmod --reference="$srcfile" "$destfile" 2>&1 && backup_chown --reference="$srcfile" "$destfile" 2>&1`
			RET=$?
		fi

		if [ $RET -eq 0 ]; then
			log "$srcfile -> $destfile"
		else
			warn "$srcfile -> $destfile failed ($msg)"
		fi
	done
}

function backup_device_restore_latest() {
	local backupdir="$1"
	local destdir="$2"
	local include_list_file="$3"
	local exclude_list_file="$4"
	local latest=`backup_get_latest "$backupdir"`
	backup_device_restore "$latest" "$destdir" "$include_list_file" "$exclude_list_file"
}

function backup_device_remove_old() {
	local backupdir="$1"
	local retain_time=$2

	[ ! -d "$backupdir" ] && return

	local OLDEST=99999999999
	local NOW=`date "+%s"`
	local MAX_KEEP_TIME=$[$NOW - $retain_time]
	for item in "$backupdir"/*; do
		local itemok=0
		if [ -d "$item" ]; then
			local itemname=`basename "$item" | awk "/[0-9]+/ { printf \"%04i-%02i-%02i %02i:%02i:%02i\", substr(\\\$1,1,4), substr(\\\$1,5,2), substr(\\\$1,7,2), substr(\\\$1,9,2),substr(\\\$1,11,2), substr(\\\$1,13,2); }"`
			if [ ! -z "$itemname" ]; then
				local itemdate=`date --date="$itemname" "+%s" 2>/dev/null`
				if [ ! -z "$itemdate" ]; then
					if [ $itemdate -lt $MAX_KEEP_TIME ]; then
						log "remove $itemname"
						rm -rf "$item"
					fi					
					itemok=1
				fi
			fi
		fi
	done
}

function backup_device_prepare() {
	local backupdir="$1"
	local device="$2"
	local label="$3"
	local filesystem="$4"
	if [ -z "$filesystem" ]; then
		filesystem="$backup_device_filesystem"
	fi

	local mounted=`getMounted "$device"`
	if [ -z "$mounted" ]; then
		echo;
	fi

	addFstabEntryForDevice "$device" "$backupdir"

}

function backup_list() {
	local backupdir="$1"
	if [ $backup_multiple_devices -eq 0 ]; then
		backup_device_list "$backupdir"
	else
		for mnt in "$backupdir"/*; do
			backup_device_list "$mnt"
		done
	fi
}

function backup_create() {
	local backupdir="$1"
	local include_list_file="$2"
	local exclude_list_file="$3"

	if [ $backup_multiple_devices -eq 0 ]; then
		backup_device_create "$backupdir" "$include_list_file" "$exclude_list_file"
	else
		for mnt in "$backupdir"/*; do
			backup_device_create "$mnt" "$include_list_file" "$exclude_list_file"
		done
	fi
}

function backup_restore() {
	local backupdir="$1"
	local destdir="$2"
	local include_list_file="$3"
	local exclude_list_file="$4"

	if [ $backup_multiple_devices -eq 0 ]; then
		backup_device_restore "$backupdir" "$destdir" "$include_list_file" "$exclude_list_file"
	else
		for mnt in "$backupdir"/*; do
			backup_device_restore "$mnt" "$destdir" "$include_list_file" "$exclude_list_file"
		done
	fi
}

function backup_restore_latest() {
	local backupdir="$1"
	local destdir="$2"
	local include_list_file="$3"
	local exclude_list_file="$4"

	if [ $backup_multiple_devices -eq 0 ]; then
		local latest=`backup_device_get_latest "$backupdir"`
		backup_device_restore "$latest" "$destdir" "$include_list_file" "$exclude_list_file"
	else
		for mnt in "$backupdir"/*; do
			local latest=`backup_device_get_latest "$mnt"`
			backup_device_restore "$latest" "$destdir" "$include_list_file" "$exclude_list_file"
		done
	fi
}

function backup_remove_old() {
	local backupdir="$1"
	local retain_time=$2
	if [ $backup_multiple_devices -eq 0 ]; then
		backup_device_remove_old "$backupdir" "$retain_time"
	else
		for mnt in "$backupdir"/*; do
			backup_device_remove_old "$mnt" "$retain_time"
		done
	fi
}


