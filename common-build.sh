#!/bin/bash

# This file stores functions for building applications
dockerImg="tony57/cde"
targetCmd="source build-tools/common-build-targets.sh"
dockerBuilderName="localBuilder"
dockerPublishList=()
ok=1
failReason=""

# Build flow management
# Input: Reason to fail the build
failBuild () {
	ok=0
	failReason=$1
}

# Entry point
commonBuild() {
	# The variable BUILD_WITH_DOCKER specifies the way to build
	if [[ -z "${BUILD_WITH_DOCKER}" ]]; then
		commonNoDockerBuild
	else
		commonDockerBuild
	fi

	$targetCmd "test"

	if [[ ! -z "${ENABLE_PUBLISH}"  ]]; then
		publishArtifact
	fi
}

# Building locally
commonNoDockerBuild() {
	echo "Local build flow without Docker starts"
	$targetCmd "init"
	$targetCmd "build"
}

# Building in a docker container
commonDockerBuild() {
	checkCde=$(docker images | grep $(dockerImg))
	version="latest"
	if [[ $? != 0 ]]; then
		echo "Fail to check existence of build docker. Exit build"
		exit 1
	elif [[ $checkCde ]]; then
		echo "Build docker already exists. Skip pulling."
	else
		echo "Build docker does not exists. Pulling from repo..."
		docker pull $dockerImg:$version
	fi

	echo "Local build flow with Docker starts"

	echo "Start container..."
	docker run \
	--name $dockerBuilderName \
	-v $(pwd):/opt/tony57 \
	-v /var/run/docker.sock:/var/run/docker.sock
	--env MODULE_DIR=${MODULE_DIR} \
	$dockerImg tail -f /dev/null

	echo "Build starts now on Docker"
	docker exec $dockerBuilderName $targetCmd "init"
	docker exec $dockerBuilderName $targetCmd "build"

	docker rm -f $dockerBuilderName
}

# State that a docker image needs to be published
publishDocker () {
	dockerPublishList+=("$1")
}

publishArtifact () {
	if [[ ! -z $(command -v docker) ]]; then
		doPublishDocker
	fi
}

# Publish docker image to remote repository
doPublishDocker () {
	# By default we build latest docker
	for img in "${dockerPublishList[@]}"; do
		echo "Publish $img to remote repository"
		docker tag $img:latest tony57/$img:latest
		docker image push tony57/$img:latest
	done
}

# Actual build flow
curDir=$(pwd)
MODULE_DIR=$(pwd)/${curDir##*/}

# Get project's build configurations
if [ -f buildConfig.sh ]; then
	source buildConfig.sh
else
	echo "buildConfig.sh not found in parent directory"
	exit 1
fi

if [[ $1 ]]; then
	echo "Run target $1"
	$1
else
	echo "No target specified. Run full build flow"
	# The build flow is started here
	commonBuild
fi

echo ""

if [[ $ok -gt 0 ]]; then
	echo "Build successful"
else
	echo "Build fails due to $failReason"
fi
