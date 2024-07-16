#!/usr/bin/env bash

if [ "${MS_NAME}" = "" ]; then
    source .env
fi

cp ${PWD}/${1}/secrets.keys ~/.config/didroom/${MS_NAME}.keys.json