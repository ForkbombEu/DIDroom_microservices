#!/usr/bin/env bash

CHAIN=verifier/verifier.yaml
CUSTOM_CODE=verifier/custom_code

if [ ! -d "${CUSTOM_CODE}" ]; then
  exit 0
fi

shopt -s nullglob
files=("${CUSTOM_CODE}"/*.zen)
shopt -u nullglob
if [ ${#files[@]} -eq 0 ]; then
  echo "No custom code files found in ${CUSTOM_CODE}." >&2
  exit 1
fi

cat <<EOF > "${CHAIN}"
steps:
  - id: transaction_id_path
    zencodeFromFile: verifier/transaction_id_path.zencode
  - id: verify_dc+sd-jwt
    zencodeFromFile: verifier/verify_dc+sd-jwt.zencode
    keysFromFile: verifier/verify_dc+sd-jwt.keys.json
    dataFromStep: transaction_id_path
    precondition:
      zencode: |
        Given I have a 'string' named 'precondition_format'
        When I set 'dc+sd-jwt' to 'dc+sd-jwt' as 'string'
        When I verify 'precondition_format' is equal to 'dc+sd-jwt'
        Then print the data
      dataFromStep: transaction_id_path
  - id: verify_ldp_vc
    zencodeFromFile: verifier/verify_ldp_vc.zencode
    keysFromFile: verifier/verify_ldp_vc.keys.json
    dataFromStep: transaction_id_path
    precondition:
      zencode: |
        Given I have a 'string' named 'precondition_format'
        When I set 'ldp_vc' to 'ldp_vc' as 'string'
        When I verify 'precondition_format' is equal to 'ldp_vc'
        Then print the data
      dataFromStep: transaction_id_path
EOF

for file in "${files[@]}"; do
    basefile=$(basename "${file}" .zen)
cat <<EOF >> "${CHAIN}"
  - id: custom_code_${basefile}_dc+sd-jwt
    zencodeFromFile: verifier/custom_code/$basefile.zen
    keysFromFile: verifier/custom_code/$basefile.keys.json
    dataFromStep: verify_dc+sd-jwt
    precondition:
      zencode: |
        Given I have a 'string' named 'precondition_type'
        Given I have a 'string' named 'precondition_format'
        When I set '$basefile' to '$basefile' as 'string'
        When I verify 'precondition_type' is equal to '$basefile'
        When I set 'dc+sd-jwt' to 'dc+sd-jwt' as 'string'
        When I verify 'precondition_format' is equal to 'dc+sd-jwt'
        Then print the data
      dataFromStep: transaction_id_path
  - id: save_result_to_file_${basefile}_dc+sd-jwt
    zencodeFromFile: verifier/save_result_to_file.zencode
    keysFromStep: verify_dc+sd-jwt
    dataFromStep: custom_code_${basefile}_dc+sd-jwt
    dataTransform: |
      const d = JSON.parse(data);
      const r = {custom_result: d};
      return JSON.stringify(r);
    precondition:
      zencode: |
        Given I have a 'string' named 'precondition_type'
        Given I have a 'string' named 'precondition_format'
        When I set '$basefile' to '$basefile' as 'string'
        When I verify 'precondition_type' is equal to '$basefile'
        When I set 'dc+sd-jwt' to 'dc+sd-jwt' as 'string'
        When I verify 'precondition_format' is equal to 'dc+sd-jwt'
        Then print the data
      dataFromStep: transaction_id_path
  - id: custom_code_${basefile}_ldp_vc
    zencodeFromFile: verifier/custom_code/$basefile.zen
    keysFromFile: verifier/custom_code/$basefile.keys.json
    dataFromStep: verify_ldp_vc
    precondition:
      zencode: |
        Given I have a 'string' named 'precondition_type'
        Given I have a 'string' named 'precondition_format'
        When I set '$basefile' to '$basefile' as 'string'
        When I verify 'precondition_type' is equal to '$basefile'
        When I set 'ldp_vc' to 'ldp_vc' as 'string'
        When I verify 'precondition_format' is equal to 'ldp_vc'
        Then print the data
      dataFromStep: transaction_id_path
  - id: save_result_to_file_${basefile}_ldp_vc
    zencodeFromFile: verifier/save_result_to_file.zencode
    keysFromStep: verify_ldp_vc
    dataFromStep: custom_code_${basefile}_ldp_vc
    dataTransform: |
      const d = JSON.parse(data);
      const r = {custom_result: d};
      return JSON.stringify(r);
    precondition:
      zencode: |
        Given I have a 'string' named 'precondition_type'
        Given I have a 'string' named 'precondition_format'
        When I set '$basefile' to '$basefile' as 'string'
        When I verify 'precondition_type' is equal to '$basefile'
        When I set 'ldp_vc' to 'ldp_vc' as 'string'
        When I verify 'precondition_format' is equal to 'ldp_vc'
        Then print the data
      dataFromStep: transaction_id_path
EOF
done
