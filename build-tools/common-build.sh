#!/bin/bash

# This file stores functions for building applications
dockerImg="tony57/cde"
buildCmd="bash build-tools/common-build-flow.sh"
dockerPublishList=()


# Entry point
commonBuild() {
	# The variable BUILD_WITH_DOCKER specifies the way to build
	if [[ -z "${BUILD_WITH_DOCKER}" ]]; then
		commonNoDockerBuild
	else
		commonDockerBuild
	fi

	publishArtifact
}

# Building locally
commonNoDockerBuild() {
	echo "Local build flow without Docker starts"
	$buildCmd
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
		echo "Build docker not exists. Pulling from repo..."
		docker pull $dockerImg:$version
	fi

	echo "Local build flow with Docker starts"

	docker run --name localBuild -v $(pwd):/opt/tony57 --env MODULE_DIR=${MODULE_DIR} --env  $dockerImg tail -f /dev/null

	docker exec localBuild $buildCmd

	docker rm -f localBuild
}

# State that a docker image needs to be published
publishDocker () {
	echo "Publish $1"
}

publishArtifact () {
	if [[ ! -z $(command -v docker) ]]; then
		doPublishDocker
	fi
}

# Publish docker image to remote repository
doPublishDocker () {
	# By default we build latest docker
	docker tag $1:latest tony57/$1:latest
	docker image push tony57/$1:$2
}

# Actual build flow here
echo "Start build script"

curDir=$(pwd)
MODULE_DIR=$(pwd)/${curDir##*/}

echo ${MODULE_DIR}

# Get project's build configurations
if [ -f buildConfig.sh ]; then
	source buildConfig.sh
else
	echo "buildConfig.sh not found in parent directory"
	exit 1
fi

# The build flow is started here
commonBuild

echo "Build suceeds"
