#!/usr/bin/env bash

AUTHZ_FILE=public/authz_server/authorize
CUSTOM_CODE=authz_server/custom_code

if [ ! -d ${CUSTOM_CODE} ] || [ ! -f ${AUTHZ_FILE} ]; then
    exit 0
fi

tmp_schema=$(mktemp)
tmp_zen=$(mktemp)
tmp_keys=$(mktemp)
tmp=$(mktemp)

echo "{}" > ${tmp_schema}
echo "{}" > ${tmp_zen}
echo "{}" > ${tmp_keys}

for f in ${CUSTOM_CODE}/*; do
    name=$(echo $f | rev | cut -d'/' -f1 | rev | cut -d'.' -f1)
    ext=$(echo $f | cut -d'.' -f2-)
    if [ -f $f ] && [ "$ext" = "schema.json" ]; then
        jq --arg name ${name} '.[$name] = input ' ${tmp_schema} $f > ${tmp} && mv ${tmp} ${tmp_schema}
    elif [ -f $f ] && [ "$ext" = "zen" ]; then
        echo "🎮 Loaded ${name} custom code"
        jq --arg name ${name} --arg contract "$(sed -z 's/\n/\\n/g' $f)" '.[$name] = $contract ' ${tmp_zen} > ${tmp} && mv ${tmp} ${tmp_zen}
    elif [ -f $f ] && [ "$ext" = "keys.json" ]; then
        jq --arg name ${name} '.[$name] = input ' ${tmp_keys} $f > ${tmp} && mv ${tmp} ${tmp_keys}
    fi
done

awk -v c="$(jq -r tostring ${tmp_zen})" '{gsub ("const contracts = .*", "const contracts = " c); print}' ${AUTHZ_FILE} > ${tmp} && mv ${tmp} ${AUTHZ_FILE}
awk -v s="$(jq -r tostring ${tmp_schema})"  '{gsub ("const schemas = .*", "const schemas = " s); print}' ${AUTHZ_FILE} > ${tmp} && mv ${tmp} ${AUTHZ_FILE}
awk -v k="$(jq -r tostring ${tmp_keys})"          '{gsub ("const keys = .*", "const keys = " k); print}' ${AUTHZ_FILE} > ${tmp} && mv ${tmp} ${AUTHZ_FILE}

rm ${tmp_schema} ${tmp_zen} ${tmp_keys}