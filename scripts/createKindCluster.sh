source globalVariables.sh

createKindCluster() {
    kindClusters=$(kind get clusters)
    if [[ $kindClusters == *"mm-local-cluster"* ]];then
        printf "\n ${green}${bold}kind cluster exists already! skipping this phase\n"
        return 1
    else 
        kind create cluster --config="../config/kind-config.yaml"        
    fi
}

createKindCluster