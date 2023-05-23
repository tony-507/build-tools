#!/bin/bash

# A script containing Docker wrappers
mounts=()

# @Private Reset all parameters back to default
resetDefault () {
	mounts=()
}

# @Private Build start container command
# Input: Image name
buildStartCmd () {
	cmd="docker run -d "

	for mount in "${mounts[@]}"; do
		cmd+="-v ${mount} "
	done

	cmd+="$1 tail -f /dev/null 2>/dev/null"
	debug_log $cmd
	resetDefault
}

# @Public Add mount path
# Input: Path in the form "hostPath:containerPath"
mount () {
	mounts+=($1)
}

# @Public Start a Docker container instance
# Input: Docker image
# Output: Docker container ID
startInstance () {
	cmd=$(buildStartCmd $1)
	debug_log "Built Docker command: $cmd"
	id=$($cmd)
	debug_log $id
}

# @Public Remove a Docker container instance
# Input: Docker container ID
removeInstance () {
	debug_log "Removing instance with id $1"
	docker rm -f $1
}
