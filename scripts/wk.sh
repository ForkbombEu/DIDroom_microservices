#!/bin/env bash

setup() {
    ## as
    if [ ! -f public/authz_server/.well-known/oauth-authorization-server.tmp ]; then
        cp public/authz_server/.well-known/oauth-authorization-server public/authz_server/.well-known/oauth-authorization-server.tmp
    fi
    sed -i \
        -e "s|{{ as_url }}|http://localhost:3000/authz_server|" \
        public/authz_server/.well-known/oauth-authorization-server


    # ci
    if [ ! -f public/credential_issuer/.well-known/openid-credential-issuer.tmp ]; then
        cp public/credential_issuer/.well-known/openid-credential-issuer public/credential_issuer/.well-known/openid-credential-issuer.tmp
    fi
    sed -i \
        -e "s|{{ ci_url }}|http://localhost:3001/credential_issuer|" \
        -e "s|{{ ci_name }}|DIDroom_Test_Issuer|" \
        public/credential_issuer/.well-known/openid-credential-issuer
    tmp=$(mktemp)
    jq --indent 4 '.credential_configurations_supported = {
            "test_credential": {
                "format": "vc+sd-jwt",
                "cryptographic_binding_methods_supported": [
                    "jwk",
                    "did:dyne:sandbox.signroom"
                ],
                "credential_signing_alg_values_supported": [
                    "ES256"
                ],
                "proof_types_supported": {
                    "jwt": {
                        "proof_signing_alg_values_supported": [
                            "ES256"
                        ]
                    }
                },
                "display": [
                    {
                        "name": "Tested Credential",
                        "locale": "en-US",
                        "logo": {
                            "uri": "https://www.connetweb.com/wp-content/uploads/2021/06/canstockphoto22402523-arcos-creator.com_-1024x1024-1.jpg",
                            "alt_text": "Test Logo"
                        },
                        "description": "a description",
                        "background_color": "#12107c",
                        "text_color": "#FFFFFF"
                    }
                ],
                "credential_definition": {
                    "type": [
                        "test_credential"
                    ],
                    "credentialSubject": {
                        "tested": {
                            "mandatory": true,
                            "display": [
                                {
                                    "name": "Is tested",
                                    "locale": "en-US"
                                }
                            ]
                        }
                    }
                }
            }
        }' public/credential_issuer/.well-known/openid-credential-issuer > $tmp && mv $tmp public/credential_issuer/.well-known/openid-credential-issuer
    jq --indent 4 '.authorization_servers = [
            "http://localhost:3000/authz_server"
        ]' public/credential_issuer/.well-known/openid-credential-issuer > $tmp && mv $tmp public/credential_issuer/.well-known/openid-credential-issuer

    ## rp
    if [ ! -f public/relying_party/.well-known/openid-relying-party.tmp ]; then
        cp public/relying_party/.well-known/openid-relying-party public/relying_party/.well-known/openid-relying-party.tmp
    fi
    sed -i \
        -e "s|{{ rp_url }}|http://localhost:3002/relying_party|" \
        -e "s|{{ rp_name }}|DIDroom_Test_RP|" \
        public/relying_party/.well-known/openid-relying-party
    jq --indent 4 '.trusted_credential_issuers = [
            "http://localhost:3001/credential_issuer"
        ]' public/relying_party/.well-known/openid-relying-party > $tmp && mv $tmp public/relying_party/.well-known/openid-relying-party
}

cleanup() {
    mv public/authz_server/.well-known/oauth-authorization-server.tmp public/authz_server/.well-known/oauth-authorization-server
    mv public/credential_issuer/.well-known/openid-credential-issuer.tmp public/credential_issuer/.well-known/openid-credential-issuer
    mv public/relying_party/.well-known/openid-relying-party.tmp public/relying_party/.well-known/openid-relying-party
}

"$@"