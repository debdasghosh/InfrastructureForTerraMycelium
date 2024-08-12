#!/usr/bin/env bash 

isDockerRunning() {
    # Check if Docker is running
    if ! systemctl is-active --quiet docker; then
        echo -e "${red}Docker is not running. Please make sure Docker is running.${reset}"
        exit 1
    fi
}
