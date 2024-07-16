#!/usr/bin/env bash

if [ "${MS_URL}" = "" ] || [ "${MS_NAME}" = "" ]; then
    source .env
fi

mkdir -p ~/.config/didroom

# lock file to prevent concurrent writing to metadata.yaml
LOCKFILE=~/.config/didroom/.lock
exec 200>"$LOCKFILE"
flock 200
trap "flock -u 200; rm -f $LOCKFILE" EXIT

# create metadata file
if [ ! -f ~/.config/didroom/metadata.yaml ]; then
    echo "# This file is generated automatically, do not edit it" > ~/.config/didroom/metadata.yaml
    echo "name: Deployed microservices" >> ~/.config/didroom/metadata.yaml
    echo "services:" >> ~/.config/didroom/metadata.yaml
fi

# if the service is already in the metadata file, update its folder and url
# otherwise add a new one
n=$(grep -n "${MS_NAME}$" ~/.config/didroom/metadata.yaml | cut -d ":" -f 1)
if [ "${n}" != "" ]; then
    tmp=$(mktemp)
    awk -v nr=$((n+1)) -v val=${PWD} 'NR==nr {$0="    folder: "'"val"'""} 1' ~/.config/didroom/metadata.yaml > $tmp && mv $tmp ~/.config/didroom/metadata.yaml
    awk -v nr=$((n+2)) -v val=${MS_URL} 'NR==nr {$0="    url: "'"val"'""} 1' ~/.config/didroom/metadata.yaml > $tmp && mv $tmp ~/.config/didroom/metadata.yaml
else
    echo "  - name: ${MS_NAME}" >> ~/.config/didroom/metadata.yaml
    echo "    folder: ${PWD}" >> ~/.config/didroom/metadata.yaml
    echo "    url: ${MS_URL}" >> ~/.config/didroom/metadata.yaml
fi

# check if keys are found
if [ -f "~/.config/didroom/${MS_NAME}.keys.json" ]; then
    cp "~/.config/didroom/${MS_NAME}.keys.json" ${PWD}/${1}/secret.keys
    echo "keys found"
    exit 1
fi

echo "keys not found"
exit 0