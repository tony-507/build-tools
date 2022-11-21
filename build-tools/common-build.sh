#!/bin/bash

# This file stores functions for building applications
dockerImg="tony57/cde"

# Common pre-build tasks
commonDockerPreBuild() {
	echo "Build flow with Docker starts"
	prepareBuildDocker
	startDockerBuilder
}

commonNoDockerBuild() {
	if [[ "$1" = "local" ]]; then
		echo "Local build flow without Docker starts"
		userBuildLocal
	else
		echo "Deployment build flow without Docker starts"
		userBuild
	fi
}

# Common post-build tasks
commonDockerPostBuild() {
	echo "Stopping Docker builder..."
	stopDockerBuilder
}

# Common build flow
commonBuild() {
	# The variable BUILD_WITH_DOCKER specifies the way to build
	if [[ -z "${BUILD_WITH_DOCKER}" ]]; then
		commonNoDockerBuild
	else
		commonDockerPreBuild
		buildInDocker
		commonDockerPostBuild
	fi
}

# Functions for building on a docker container
prepareBuildDocker() {
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
}

# Start a docker container with shared directory to store output
startDockerBuilder () {
	docker run --name localBuild -v $(pwd):/opt/tony57 --env MODULE_DIR=${MODULE_DIR} --env  $dockerImg tail -f /dev/null
}

buildInDocker () {
	docker exec localBuild bash build-tools/common-build-docker.sh
}

stopDockerBuilder () {
	docker rm -f localBuild
}

# Publish Docker to remote repository
publishDocker () {
	# By default we build latest docker
	docker tag $1:latest tony57/$1:$2
	docker image push tony57/$1:$2
}

# Actual build flow here
echo "Start build script"

curDir=$(pwd)
MODULE_DIR=$(pwd)/${curDir##*/}

# Get project's build configurations
if [ -f buildConfig.sh ]; then
	source buildConfig.sh
else
	echo "build.sh not found in parent directory"
	exit 1
fi

# The build flow is started here
commonBuild

echo "Build suceeds"
