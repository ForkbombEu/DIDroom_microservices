#!/bin/env bash

setup() {
    ## as
    if [ ! -f public/authz_server/.well-known/oauth-authorization-server.tmp ]; then
        cp public/authz_server/.well-known/oauth-authorization-server public/authz_server/.well-known/oauth-authorization-server.tmp
    fi
    sed -i \
        -e "s|{{ as_url }}|http://localhost:3000/authz_server|g" \
        public/authz_server/.well-known/oauth-authorization-server

    # ci
    if [ ! -f public/credential_issuer/.well-known/openid-credential-issuer.tmp ]; then
        cp public/credential_issuer/.well-known/openid-credential-issuer public/credential_issuer/.well-known/openid-credential-issuer.tmp
    fi
    sed -i \
        -e "s|{{ ci_url }}|http://localhost:3001/credential_issuer|g" \
        -e "s|{{ ci_name }}|DIDroom_Test_Issuer|g" \
        public/credential_issuer/.well-known/openid-credential-issuer
    tmp=$(mktemp)
    jq --indent 4 '.credential_configurations_supported = {
            "test_credential": {
                "format": "dc+sd-jwt",
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
                "vct": "test_credential",
                "claims": [
                    {
                        "path": [ "tested" ],
                        "mandatory": true,
                        "display": [
                            {
                                "name": "Is tested",
                                "locale": "en-US"
                            }
                        ]
                    }
                ]
            },
            "UniversityDegree_LDP_VC": {
                "format": "ldp_vc",
                "cryptographic_binding_methods_supported": [
                    "jwk",
                    "did:dyne:sandbox.signroom"
                ],
                "credential_signing_alg_values_supported": [
                    "Ed25519Signature2018"
                ],
                "credential_definition": {
                    "@context": [
                        "https://www.w3.org/ns/credentials/v2",
                        "https://www.w3.org/ns/credentials/examples/v2"
                    ],
                    "type": [
                        "VerifiableCredential",
                        "UniversityDegreeCredential"
                    ]
                },
                "claims": [
                    {
                        "path": ["credentialSubject", "given_name"],
                        "display": [
                            {
                                "name": "Given Name",
                                "locale": "en-US"
                            }
                        ]
                    },
                    {
                        "path": ["credentialSubject", "family_name"],
                        "display": [
                            {
                                "name": "Surname",
                                "locale": "en-US"
                            }
                        ]
                    },
                    {
                        "path": ["credentialSubject", "degree"]
                    },
                    {
                        "path": ["credentialSubject", "gpa"],
                        "mandatory": true,
                        "display": [
                            {
                                "name": "GPA"
                            }
                        ]
                    }
                ],
                "display": [
                    {
                        "name": "University Credential",
                        "locale": "en-US",
                        "logo": {
                            "uri": "https://university.example.edu/public/logo.png",
                            "alt_text": "a square logo of a university"
                        },
                        "description": "University Degree Credential",
                        "background_color": "#12107c",
                        "text_color": "#FFFFFF"
                    }
                ]
            }
        }' public/credential_issuer/.well-known/openid-credential-issuer > $tmp && mv $tmp public/credential_issuer/.well-known/openid-credential-issuer
    jq --indent 4 '.authorization_servers = [
            "http://localhost:3000/authz_server"
        ]' public/credential_issuer/.well-known/openid-credential-issuer > $tmp && mv $tmp public/credential_issuer/.well-known/openid-credential-issuer
}

cleanup() {
    mv public/authz_server/.well-known/oauth-authorization-server.tmp public/authz_server/.well-known/oauth-authorization-server
    mv public/credential_issuer/.well-known/openid-credential-issuer.tmp public/credential_issuer/.well-known/openid-credential-issuer
}

"$@"