#!/usr/bin/env bash 
source globalVariables.sh

if minikube status | grep -q "host: Running"; then 
    echo -e "${green}Minikube is running${reset}"
else 
    echo -e "${red}Minikube is down, please start the Minikube cluster.${reset}"
    exit 1
fi