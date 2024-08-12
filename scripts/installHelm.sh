#!/bin/bash

helm version

if [ $? -eq 0 ]; then 
    echo -e "${bold}${green}Helm is already installed, skipping the installation.${reset}" 
else 
    # installing Helm 
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    chmod 700 get_helm.sh
    ./get_helm.sh
    
    # communicating if the script is installed
    if [ $? -eq 0]; then 
        echo "Helm succesfully installed"
    else 
        echo "Error occured, Helm could not be installed"
    fi
fi




