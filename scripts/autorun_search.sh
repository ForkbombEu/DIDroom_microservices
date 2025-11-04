#!/usr/bin/env bash

if [ "${MS_URL}" = "" ] || [ "${MS_NAME}" = "" ]; then
    source .env
fi

if [ "$1" != "authz_server" ] && [ "$1" != "credential_issuer" ] && [ "$1" != "verifier" ]; then
    echo "Unknown value for '$1'. Must be one of: authz_server, credential_issuer, verifier." >&2
    exit 1
fi

baseUrl=$(awk -F/ '{print $3}' <<<"${MS_URL}")

if [ "${XDG_CONFIG_HOME}" = "" ]; then
    CONFIG_DIR="${HOME}/.config/didroom"
else
    CONFIG_DIR="${XDG_CONFIG_HOME}/didroom"
fi
METADATA_FILE="${CONFIG_DIR}/metadata.yaml"
MS_KEYS_FILE="${CONFIG_DIR}/${baseUrl}-${MS_NAME}.keys.json"
DEST_KEYS_FILE="${PWD}/${1}/secrets.keys"

mkdir -p ${CONFIG_DIR}

# lock file to prevent concurrent writing to metadata.yaml
LOCKFILE="${CONFIG_DIR}/.lock"
exec 200>"${LOCKFILE}"
flock 200
trap 'flock -u 200; rm -f "${LOCKFILE}"' EXIT

# create metadata file
if [ ! -f "${METADATA_FILE}" ]; then
    cat <<EOF >${METADATA_FILE}
# This file is generated automatically, do not edit it
name: Deployed microservices
services:
EOF
fi

# if the service is already in the metadata file, update its folder and url
# otherwise add a new one
n=$(grep -n "^  - name: ${MS_NAME}$" "${METADATA_FILE}" | cut -d ":" -f 1)
if [ "${n}" != "" ]; then
    tmp=$(mktemp)
    awk -v nr=$((n + 1)) -v val=${PWD} 'NR==nr {$0="    folder: "'"val"'""} 1' "${METADATA_FILE}" >$tmp && mv $tmp "${METADATA_FILE}"
    awk -v nr=$((n + 2)) -v val=${MS_URL} 'NR==nr {$0="    url: "'"val"'""} 1' "${METADATA_FILE}" >$tmp && mv $tmp "${METADATA_FILE}"
else
    cat <<EOF >>"${METADATA_FILE}"
  - name: ${MS_NAME}
    folder: ${PWD}
    url: ${MS_URL}
EOF
fi

# check if keys are found
if [ -f "${MS_KEYS_FILE}" ]; then
    cp ${MS_KEYS_FILE} ${DEST_KEYS_FILE}
    if [ ${1} != "verifier" ]; then
        kid=$(jq -r '.kid' ${DEST_KEYS_FILE})
    else
        kid=$(jq -r '.did' ${MS_KEYS_FILE})
    fi
    echo "keys found: ${kid}"
    exit 1
fi

echo "keys not found"
exit 0
