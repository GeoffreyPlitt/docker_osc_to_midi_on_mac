#!/bin/bash

# This script runs "container_action.sh" in the docker container.

set -ex

# Use the centralized docker runner to run container stuff
./run_docker.sh ./container_action.sh