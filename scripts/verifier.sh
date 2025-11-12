#!/usr/bin/env bash

CHAIN=verifier/verifier.chain.yaml
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
  - id: verify_vptoken
    zencodeFromFile: verifier/verify_vptoken.zencode
    dataFromStep: transaction_id_path
    onError:
      zencodeFromFile: verifier/error.zencode
      dataFromStep: transaction_id_path
      keys:
        error: Cryptographic verification failed
EOF

for file in "${files[@]}"; do
    basefile=$(basename "${file}" .zen)
cat <<EOF >> "${CHAIN}"
  - id: custom_code_${basefile}
    zencodeFromFile: verifier/custom_code/$basefile.zen
    keysFromFile: verifier/custom_code/$basefile.keys.json
    dataFromStep: verify_vptoken
    precondition:
      zencode: |
        Given I have a 'string' named 'precondition_type'
        When I set '$basefile' to '$basefile' as 'string'
        When I verify 'precondition_type' is equal to '$basefile'
        Then print the data
      dataFromStep: transaction_id_path
    onError:
      zencodeFromFile: verifier/error.zencode
      dataFromStep: transaction_id_path
      keys:
        error: Custom code verification $basefile failed
  - id: save_result_to_file_${basefile}
    zencodeFromFile: verifier/save_result_to_file.zencode
    keysFromStep: verify_vptoken
    dataFromStep: custom_code_${basefile}
    dataTransform: |
      const d = JSON.parse(data);
      const r = {custom_result: d};
      return JSON.stringify(r);
    precondition:
      zencode: |
        Given I have a 'string' named 'precondition_type'
        When I set '$basefile' to '$basefile' as 'string'
        When I verify 'precondition_type' is equal to '$basefile'
        Then print the data
      dataFromStep: transaction_id_path
EOF
done
