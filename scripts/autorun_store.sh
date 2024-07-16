#!/usr/bin/env bash

if [ "${MS_URL}" = "" ] || [ "${MS_NAME}" = "" ]; then
    source .env
fi

baseUrl=$(awk -F/ '{print $3}' <<<"${MS_URL}")
cp ${PWD}/${1}/secrets.keys ~/.config/didroom/${baseUrl}-${MS_NAME}.keys.json