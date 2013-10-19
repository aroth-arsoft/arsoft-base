#!/bin/bash

function getArg() {
	arg="$1"
	defarg="$2"
	if [ ! -z "$arg" -a "${arg:0:1}" != "-" ]; then
		echo "$arg"
		RET=0
	else
		echo "$defarg"
		RET=1
	fi
	return $RET
}
