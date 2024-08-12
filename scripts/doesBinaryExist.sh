doesBinaryExist() {
    if ! [[ -x "$(command -v $1)" ]] 
    then 
        echo "$1 could not be found"
        exit 1
    fi
}

