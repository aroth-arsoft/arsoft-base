#!/bin/bash

THIS_SCRIPT_NAME='shlib.sh'
DEFAULT_SHLIB_DIR=/usr/share/arsoft/shlib

if [ -f `dirname $0`/$THIS_SCRIPT_NAME ]; then
	SHLIB_DIR=`dirname $0`
else
	SHLIB_DIR=$DEFAULT_SHLIB_DIR
fi

function load_shlib_module() {
	if [ -e "$SHLIB_DIR/$1.sh" ]; then
		source "$SHLIB_DIR/$1.sh"
	else
		echo "Failed to load shlib module $1"
	fi
}

function shlib_install() {
	# do not use SHLIB_DIR variable here, since it may
	# point to the current directory with the sources
	SOURCE_DIR=`dirname $0`
	SYMLINK_ONLY=1

	if [ -z "$DESTDIR" ]; then
		DESTDIR="$DEFAULT_SHLIB_DIR"
	fi

	if [ ! -d "$DESTDIR" ]; then
		log "mkdir -p $DESTDIR 2>&1"
	       	msg=`mkdir -p "$DESTDIR" 2>&1`
		RET=$?
	else
		RET=0
	fi
	if [ $RET -eq 0 ]; then

		if [ $SYMLINK_ONLY -eq 0 ]; then
			msg=`cp "$SOURCE_DIR"/*.sh "$DESTDIR" 2>&1`
			msg=`[ $? -eq 0 ] && chmod +x "${DESTDIR}/${THIS_SCRIPT_NAME}" 2>&1`
			RET=$?
		else
			for shfile in "$SOURCE_DIR"/*.sh; do
				shfilename=`basename $shfile`
				shrealfile=`readlink -f "$shfile"`
				if [ -L "${DESTDIR}/${shfilename}" ]; then
					log "rm ${DESTDIR}/${shfilename}"
				       	rm "${DESTDIR}/${shfilename}"
				fi
				log "ln -sf $shrealfile $DESTDIR/$shfilename 2>&1"
				msg=`ln -sf "$shrealfile" "${DESTDIR}/${shfilename}" 2>&1`
				RET=$?
				[ $RET -ne 0 ] && break
			done

			if [ $RET -eq 0 ]; then
			       	msg=`chmod +x \`readlink -f "${DESTDIR}/${THIS_SCRIPT_NAME}"\` 2>&1`
				RET=$?
			fi
		fi
	fi
	if [ $RET -ne 0 ]; then
		err "failed to install shlib to $DESTDIR, error $msg"
	fi
}

function shlib_uninstall() {
	# do not use SHLIB_DIR variable here, since it may
	# point to the current directory with the sources

	if [ -z "$DESTDIR" ]; then
		DESTDIR="$DEFAULT_SHLIB_DIR"
	fi

	[ -d "$DESTDIR" ] && msg=`rm -rf "$DESTDIR" 2>&1`
	RET=$?
	if [ $RET -ne 0 ]; then
		err "failed to uninstall shlib from $DESTDIR"
	fi
}

function usage() {
	echo "usage: "
	echo "  install shlib:   $0 install"
	echo "  uninstall shlib: $0 uninstall"
	echo "  use shlib within your script files:"
	echo "  source $0"
	exit 0
}

# load all modules
load_shlib_module logging
load_shlib_module args
load_shlib_module backup
load_shlib_module disk

if [ `basename $0` == "$THIS_SCRIPT_NAME" ]; then
	# started directly, so check options

	INSTALL=0
	UNINSTALL=0
	# parse command line arguments
	while [ $# -ne 0 ]; do
		case "$1" in
			"-?") usage;;
			"-h") usage;;
			"--help") usage;;
			"--verbose"|"-v") logging_verbose 1; ;;
			"install") INSTALL=1; ;;
			"uninstall") UNINSTALL=1; ;;
			*)
				echo "Unrecognized parameter $1"
			;;
		esac
		shift
	done



	if [ $INSTALL -ne 0 ]; then
		shlib_install
	elif [ $UNINSTALL -ne 0 ]; then
		shlib_uninstall
	else
		echo "no command specified."
		usage
	fi
	
fi



