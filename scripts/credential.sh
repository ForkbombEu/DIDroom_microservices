#!/usr/bin/env bash

CHAIN=credential_issuer/credential.chain.yaml
CUSTOM_CODE=credential_issuer/custom_code
WELL_KNOWN=public/credential_issuer/.well-known/openid-credential-issuer

if [ ! -d ${CUSTOM_CODE} ] || [ ! -f ${WELL_KNOWN} ]; then
  echo "Custom code directory or well-known file not found."
  exit 1
fi

# get all vct from well_known
sd_jwts=$(jq -r '.credential_configurations_supported | to_entries[] | select(.value.format == "dc+sd-jwt") | .value.vct' "${WELL_KNOWN}")
ldp_vcs=$(jq -r '.credential_configurations_supported | to_entries[] | select(.value.format == "ldp_vc") | .key' "${WELL_KNOWN}")

if [ -z "${sd_jwts}" ] || [ -z "${ldp_vcs}" ]; then
  echo "No sd-jwts or ldp_vcs found in the well-known file."
  exit 1
fi

cat <<EOF > ${CHAIN}
steps:
  - id: Verify
    zencodeFromFile: credential_issuer/credential_1_verify.zencode
    keysFromFile: credential_issuer/credential.keys.json
  - id: Introspection
    zencodeFromFile: credential_issuer/credential_2_token_to_introspection.zencode
    dataFromStep: Verify
EOF

for sd_jwt in ${sd_jwts}; do
cat <<EOF >> ${CHAIN}
  - id: Custom dc+sd-jwt $sd_jwt
    precondition:
      zencode: |
        Given I have a 'string' named 'credential_configuration_id'
        When I set 'condition' to '$sd_jwt' as 'string'
        When I verify 'credential_configuration_id' is equal to 'condition'
        Then print the string '$sd_jwt'
      dataFromStep: Verify
    zencodeFromFile: credential_issuer/custom_code/$sd_jwt.zen
    keysFromFile: credential_issuer/custom_code/$sd_jwt.keys.json
    dataFromStep: Introspection
  - id: sd_jwt for $sd_jwt
    precondition:
      zencode: |
        Given I have a 'string' named 'credential_configuration_id'
        When I set 'condition' to '$sd_jwt' as 'string'
        When I verify 'credential_configuration_id' is equal to 'condition'
        Then print the string '$sd_jwt'
      dataFromStep: Verify
    zencodeFromFile: credential_issuer/credential_4_sd_jwt.zencode
    keysFromStep: Verify
    dataFromStep: Custom dc+sd-jwt $sd_jwt
EOF
done
for ldp_vc in ${ldp_vcs}; do
cat <<EOF >> ${CHAIN}
  - id: Custom ldp_vc $ldp_vc
    precondition:
      zencode: |
        Given I have a 'string' named 'credential_configuration_id'
        When I set 'condition' to '$ldp_vc' as 'string'
        When I verify 'credential_configuration_id' is equal to 'condition'
        Then print the string '$ldp_vc'
      dataFromStep: Verify
    zencodeFromFile: credential_issuer/custom_code/$ldp_vc.zen
    keysFromFile: credential_issuer/custom_code/$ldp_vc.keys.json
    dataFromStep: Introspection
  - id: rdfcanon for $ldp_vc
    precondition:
      zencode: |
        Given I have a 'string' named 'credential_configuration_id'
        When I set 'condition' to '$ldp_vc' as 'string'
        When I verify 'credential_configuration_id' is equal to 'condition'
        Then print the string '$ldp_vc'
      dataFromStep: Verify
    zencodeFromFile: credential_issuer/credential_4_rdfcanon.zencode
    keysFromStep: Verify
    dataFromStep: Custom ldp_vc $ldp_vc
  - id: w3c_vc for $ldp_vc
    precondition:
      zencode: |
        Given I have a 'string' named 'credential_configuration_id'
        When I set 'condition' to '$ldp_vc' as 'string'
        When I verify 'credential_configuration_id' is equal to 'condition'
        Then print the string '$ldp_vc'
      dataFromStep: Verify
    zencodeFromFile: credential_issuer/credential_5_ldp_vc.zencode
    keysFromStep: rdfcanon for $ldp_vc
    dataFromStep: Custom ldp_vc $ldp_vc
EOF
done
