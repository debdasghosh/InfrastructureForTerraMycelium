#!/bin/bash

source determineOsPackageManager.sh

terraform version

if [ $? -eq 0 ]; then 
    echo -e "${bold}${green}Terraform is already installed, skipping the installation.${reset}" 
else 
    # installing Terraform 
    packageManagerInstallCommand terraform
    
    # communicating if the script is installed
    if [ $? -eq 0]; then 
        echo "Terraform succesfully installed"
    else 
        echo "Error occured, Terraform could not be installed"
    fi
fi



