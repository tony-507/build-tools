#!/bin/bash

# Get project's build configurations
if [ -f buildConfig.sh ]; then
	source buildConfig.sh
else
	echo "buildConfig.sh not found in parent directory"
	exit 1
fi

# Run module-specific tests
commonTest () {
	echo -e "\nStart running tests\n"
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

commonTest
