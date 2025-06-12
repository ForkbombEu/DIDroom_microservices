#!/usr/bin/env bash

CHAIN=credential_issuer/credential.chain.yaml
CUSTOM_CODE=credential_issuer/custom_code
WELL_KNOWN=public/credential_issuer/.well-known/openid-credential-issuer

if [ ! -d ${CUSTOM_CODE} ] || [ ! -f ${WELL_KNOWN} ]; then
    exit 0
fi

# get all vct from well_known
# vcts=$(jq -r '.credential_configurations_supported.[].vct' ${WELL_KNOWN})
vcts=$(jq -r '.credential_configurations_supported | to_entries[] | select(.value.format == "dc+sd-jwt") | .value.vct' "${WELL_KNOWN}")
ldp_keys=$(jq -r '.credential_configurations_supported | to_entries[] | select(.value.format == "ldp_vc") | .key' "${WELL_KNOWN}")

chain="  "
for vct in ${vcts}; do
cat <<EOF >> ${CHAIN}
  - id: Custom vc+sd-jwt $vct
    precondition:
      zencode: |
        Given I have a 'string' named 'vct'
        When I set 'condition' to '$vct' as 'string'
        When I verify 'vct' is equal to 'condition'
        Then print the string '$vct'
      dataFromStep: Verify
    zencodeFromFile: credential_issuer/custom_code/$vct.zen
    keysFromFile: credential_issuer/custom_code/$vct.keys.json
    dataFromStep: Introspection
  - id: sd_jwt for $vct
    precondition:
      zencode: |
        Given I have a 'string' named 'vct'
        When I set 'condition' to '$vct' as 'string'
        When I verify 'vct' is equal to 'condition'
        Then print the string '$vct'
      dataFromStep: Verify
    zencodeFromFile: credential_issuer/credential_4_sd_jwt.zencode
    keysFromStep: Verify
    dataFromStep: Custom $vct
EOF
done
for ldp_key in ${ldp_keys}; do
cat <<EOF >> ${CHAIN}
  - id: Custom ldp_vc $ldp_keys
    precondition:
      zencode: |
        Given I have a 'string' named 'vct'
        When I set 'condition' to '$vct' as 'string'
        When I verify 'vct' is equal to 'condition'
        Then print the string '$vct'
      dataFromStep: Verify
    zencodeFromFile: credential_issuer/custom_code/$vct.zen
    keysFromFile: credential_issuer/custom_code/$vct.keys.json
    dataFromStep: Introspection
  - id: w3c_vc for $ldp_keys
    precondition:
      zencode: |
        Given I have a 'string' named 'vct'
        When I set 'condition' to '$vct' as 'string'
        When I verify 'vct' is equal to 'condition'
        Then print the string '$vct'
      dataFromStep: Verify
    zencodeFromFile: credential_issuer/credential_4_sd_jwt.zencode
    keysFromStep: Verify
    dataFromStep: Custom $vct
EOF
done
