#!/bin/bash

# Debug build
debug_log () {
	if [[ ${DEBUG_BUILD} ]]; then
		echo "$date $@" > debug.log
	fi
}

# Debug + echo
debug_echo () {
	debug_log $@
	echo $@
}

# Setup configuration variables
setBuildConfig () {
	echo "Debug? ${DEBUG_BUILD}"
}

setBuildConfig

source buildConfig.sh

userBuild
