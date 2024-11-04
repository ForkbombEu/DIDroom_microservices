#!/usr/bin/env bash

AUTHZ_FILE=public/authz_server/authorize
CUSTOM_CODE=authz_server/custom_code

if [ ! -d ${CUSTOM_CODE} ] || [ ! -f ${AUTHZ_FILE} ]; then
    exit 0
fi

tmp_schema=$(mktemp)
tmp=$(mktemp)

echo "{}" > ${tmp_schema}

for f in ${CUSTOM_CODE}/*.schema.json; do
    name=$(echo $f | rev | cut -d'/' -f1 | rev | cut -d'.' -f1)
    jq --arg name ${name} '.[$name] = input ' ${tmp_schema} $f > ${tmp} && mv ${tmp} ${tmp_schema}
done

awk -v s="$(jq -r tostring ${tmp_schema})"  '{gsub ("const schemas = .*", "const schemas = " s); print}' ${AUTHZ_FILE} > ${tmp} && mv ${tmp} ${AUTHZ_FILE}

rm ${tmp_schema}