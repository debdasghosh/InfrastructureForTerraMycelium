#!/usr/bin/env bash 

# global variables
source globalVariables.sh

# adding the scripts 
source determineOsPackageManager.sh
source installMinikube.sh
source doesBinaryExist.sh
source isDockerRunning.sh
source installHelm.sh
source installTerraform.sh

