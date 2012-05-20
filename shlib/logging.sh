#!/bin/bash

LOGGING_LEVEL_FATAL=0
LOGGING_LEVEL_ERROR=1
LOGGING_LEVEL_WARNING=2
LOGGING_LEVEL_INFO=3
LOGGING_LEVEL_DEBUG=4
LOGGING_LEVEL=$LOGGING_LEVEL_WARNING
LOGGING_SYSLOG=0
LOGGING_NAME=$0
LOGGING_LOGGER=`which logger`

function logging_verbose() {
	LOGGING_LEVEL=$LOGGING_LEVEL_INFO
}

function logging_debug() {
	LOGGING_LEVEL=$LOGGING_LEVEL_DEBUG
}

function log() {
	echo $*
	if [ $LOGGING_SYSLOG -ne 0 ]; then
		$LOGGING_LOGGER -t "$LOGGING_NAME" "$*"
	fi
}

function fatal() {
	if [ $LOGGING_LEVEL -ge $LOGGING_LEVEL_FATAL ]; then
		echo $*
		if [ $LOGGING_SYSLOG -ne 0 ]; then
			$LOGGING_LOGGER -t "$LOGGING_NAME" "$*"
		fi
	fi
}

function err() {
	if [ $LOGGING_LEVEL -ge $LOGGING_LEVEL_ERROR ]; then
		echo $*
		if [ $LOGGING_SYSLOG -ne 0 ]; then
			$LOGGING_LOGGER -t "$LOGGING_NAME" "$*"
		fi
	fi
}

function warn() {
	if [ $LOGGING_LEVEL -ge $LOGGING_LEVEL_WARNING ]; then
		echo $*
		if [ $LOGGING_SYSLOG -ne 0 ]; then
			$LOGGING_LOGGER -t "$LOGGING_NAME" "$*"
		fi
	fi
}

function info() {
	if [ $LOGGING_LEVEL -ge $LOGGING_LEVEL_INFO ]; then
		echo $*
		if [ $LOGGING_SYSLOG -ne 0 ]; then
			$LOGGING_LOGGER -t "$LOGGING_NAME" "$*"
		fi
	fi
}

function debug() {
	if [ $LOGGING_LEVEL -ge $LOGGING_LEVEL_DEBUG ]; then
		echo $*
		if [ $LOGGING_SYSLOG -ne 0 ]; then
			$LOGGING_LOGGER -t "$LOGGING_NAME" "$*"
		fi
	fi
}

function logcmd() {
	log $*
	$*
}

function logcmdq() {
	log $*
	$* &> /dev/null 
}

