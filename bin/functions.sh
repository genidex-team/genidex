#!/bin/bash

load_env_file() {
    #https://stackoverflow.com/questions/19331497/set-environment-variables-from-file-of-key-value-pairs
    env_file=$1
    if [ -f $env_file ]; then
        unamestr=$(uname)
        if [ "$unamestr" = 'Linux' ]; then
            string=$(cat $env_file | sed 's/#.*//g' | sed 's/\s*=\s*/=/' | xargs -d '\n')
        elif [ "$unamestr" = 'FreeBSD' ] || [ "$unamestr" = 'Darwin' ]; then
            string=$(cat $env_file | sed 's/#.*//g' | sed 's/ *= */=/' | xargs -0)
        fi
        echo $string > tmp_clean.env
        set -o allexport
            source tmp_clean.env
        set +o allexport
        rm -fr tmp_clean.env
        # export $string
        # printenv | grep 'NGINX'
        # export $string
    else
        echo "$env_file does not exist."
    fi
}