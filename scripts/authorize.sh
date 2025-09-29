#!/usr/bin/env bash

AUTHZ_FILE=public/authz_server/authorize
CUSTOM_CODE=authz_server/custom_code
CHAIN=authz_server/authorize_backend.chain.yaml

if [ ! -d ${CUSTOM_CODE} ] || [ ! -f ${AUTHZ_FILE} ]; then
    exit 0
fi

# authorize frontend page

tmp_schema=$(mktemp)
tmp=$(mktemp)

echo "{}" > ${tmp_schema}

for f in ${CUSTOM_CODE}/*.schema.json; do
    name=$(echo $f | rev | cut -d'/' -f1 | rev | cut -d'.' -f1)
    jq --arg name ${name} '.[$name] = input ' ${tmp_schema} $f > ${tmp} && mv ${tmp} ${tmp_schema}
done

awk -v s="$(jq -r tostring ${tmp_schema})"  '{gsub ("const schemas = .*", "const schemas = " s); print}' ${AUTHZ_FILE} > ${tmp} && mv ${tmp} ${AUTHZ_FILE}

rm ${tmp_schema}

# authorize backend chain
zen_files=("${CUSTOM_CODE}"/*.zen)
shopt -u nullglob
if [ ${#zen_files[@]} -eq 0 ]; then
  echo "No custom code files found in ${CUSTOM_CODE}." >&2
  exit 1
fi

cat <<EOF > "${CHAIN}"
steps:
  - id: authorize_1_choose_cc
    zencode: |
      Given I have a 'string' named 'form_input_and_params'
      When I create json unescaped object of 'form_input_and_params'
      Then print the data from 'json_unescaped_object'
EOF

for file in "${zen_files[@]}"; do
    basefile=$(basename "${file}" .zen)
cat <<EOF >> "${CHAIN}"
  - id: custom_code_${basefile}_2
    zencodeFromFile: authz_server/custom_code/$basefile.zen
    keysFromFile: authz_server/custom_code/$basefile.keys.json
    dataFromStep: authorize_1_choose_cc
    dataTransform: |
      return JSON.stringify((JSON.parse(data)).data)
    precondition:
      zencode: |
        Given I have a 'string' named 'custom_code'
        When I set '$basefile' to '$basefile' as 'string'
        When I verify 'custom_code' is equal to '$basefile'
        Then print the data
      dataFromStep: authorize_1_choose_cc
    onError:
      zencodeFromFile: authz_server/authorize_error.zencode
      keysFromStep: authorize_1_choose_cc
      data:
        error: server_error
      fail: false
  - id: merge_output_${basefile}_3
    zencode: |
      Given I have a 'string dictionary' named 'data'
      Given I have a 'string dictionary' named 'params'
      Then print the 'data'
      Then print the data from 'params'
    dataFromStep: authorize_1_choose_cc
    keysFromStep: custom_code_${basefile}_2
    dataTransform: |
      return JSON.stringify({params: (JSON.parse(data)).params})
    precondition:
      zencode: |
        Given I have a 'string' named 'custom_code'
        When I set '$basefile' to '$basefile' as 'string'
        When I verify 'custom_code' is equal to '$basefile'
        Then print the data
      dataFromStep: authorize_1_choose_cc
    onError:
      zencodeFromFile: authz_server/authorize_error.zencode
      keysFromStep: authorize_1_choose_cc
      data:
        error: server_error
      fail: false
  - id: authorize_${basefile}_4_get_access_code
    zencodeFromFile: authz_server/ru_to_ac.zen
    dataFromStep: merge_output_${basefile}_3
    keysFromFile: authz_server/ru_to_ac.keys.json
    precondition:
      zencode: |
        Given I have a 'string' named 'custom_code'
        When I set '$basefile' to '$basefile' as 'string'
        When I verify 'custom_code' is equal to '$basefile'
        Then print the data
      dataFromStep: authorize_1_choose_cc
    onError:
      zencodeFromFile: authz_server/authorize_error.zencode
      keysFromStep: authorize_1_choose_cc
      data:
        error: server_error
      fail: false
EOF
done
