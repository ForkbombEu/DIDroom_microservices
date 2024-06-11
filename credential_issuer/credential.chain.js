() => {
    const chain = {
        steps: [
            {
                id: "credential_1_verify",
                zencodeFromFile: "credential_issuer/credential_1_verify.zencode",
                keysFromFile: "credential_issuer/credential.keys.json",
                onAfter: (result, zencode) => {
                    customChain.steps[2] = {
                            id: "credential_3_custom_code",
                            zencodeFromFile: `credential_issuer/custom_code/${JSON.parse(result).vct}.zen`,
                            keysFromFile: `credential_issuer/custom_code/${JSON.parse(result).vct}.keys.json`,
                            dataFromStep: "credential_2_token_to_introspection"
                    }
                    console.log(customChain)
                }
            },
            {
                id: "credential_2_token_to_introspection",
                zencodeFromFile: "credential_issuer/credential_2_token_to_introspection.zencode",
                dataFromStep: "credential_1_verify"
            },
            {},
            {
                id: "credential_4_sd_jwt",
                zencodeFromFile: "credential_issuer/credential_4_sd_jwt.zencode",
                dataFromStep: "credential_3_custom_code",
                keysFromStep: "credential_1_verify"
            },
        ]
    }
    globalThis.customChain = chain
    return chain
}
