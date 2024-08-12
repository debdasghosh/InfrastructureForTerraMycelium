#!/bin/bash

minikube version

if [ $? -eq 0 ]; then 
    echo -e "${bold}${green}Minikube is already installed, skipping the installation.${reset}" 
else 
    # installing minikube 
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    
    # communicating if the script is installed
    if [ $? -eq 0]; then 
        echo "Minikube succesfully installed"
    else 
        echo "Error occured, Minikube could not be installed"
    fi
fi



