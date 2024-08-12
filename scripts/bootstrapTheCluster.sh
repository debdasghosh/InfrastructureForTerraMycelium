#!/bin/bash
source installDependencies.sh

# checking to see if docker exist
doesBinaryExist "docker"

# check to see if docker is running 
isDockerRunning

# starting the cluster
if minikube status >/dev/null 2>&1; then
  echo "Minikube cluster is already running."
else
  echo "Starting Minikube cluster..."
  minikube start
fi
