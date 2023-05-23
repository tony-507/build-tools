#!/bin/bash

debug_log () {
	if [[ ${DEBUG_BUILD} ]]; then
		echo "$date $@" > debug.log
	fi
    echo $@
}

initBuild () {
    debug_log "init build"
    if [[ ${DEBUG_BUILD} ]]; then
        debug_log "debug=true"
    fi
}

userBuild_start () {
    :
}

userBuild_end () {
    userBuild
}

userTest_start () {
    :
}

userTest_end () {
    debug_log "Start running tests"
    userTest
    validateTestResult
}

# Check test results by probing test_details*.xml
validateTestResult () {
	echo "Validating test reports..."
	for f in $(find . -name test_detail*.xml); do
		totalTestCnt=$(grep failures $f | sed 's/.*tests="\([0-9]*\)".*/\1/' | paste -sd+ - | bc)
		failCnt=$(grep failures $f | sed 's/.*failures="\([0-9]*\)".*/\1/' | paste -sd+ - | bc)
		if [[ failCnt -ne "0" ]]; then
			echo "In $(basename $f), $failCnt out of $totalTestCnt tests fail"
			ok=0
			failReason="low pass rate in tests"
		else
			echo "$(basename $f) has pass rate 100%"
		fi
	done
}

build () {
    userBuild_start
    userBuild_end
}

test () {
    userTest_start
    userTest_end
}


# Get project's build configurations
if [ -f buildConfig.sh ]; then
	source buildConfig.sh
else
	echo "buildConfig.sh not found in parent directory"
	exit 1
fi

if [[ $# -eq 0 ]]; then
    debug_log "No target specified"
    exit 1
fi

case $1 in
    "init")
        initBuild
        ;;
    "build")
        build
        ;;
    "test")
        test
        ;;
    *)
        debug_log "Unknown target $1"
        exit 1
        ;;
esac
