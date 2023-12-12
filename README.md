<div align="center">

# DIDroom standalone microservices

### Implementation of the [OpenID4VC](https://openid.net/sg/openid4vc/) with the [Zenroom stack](https://forkbomb.solutions/component/zenroom/)

</div>

<p align="center">
   <img src="https://github.com/ForkbombEu/DIDroom/raw/main/images/DIDroom_logo.png" width="370">
</p>

DIDroom microservices is a comprehensive open-source implementation of the OpenID4VC
"OpenID for Verifiable Credential" protocols, designed to easily deploy
the entire credential issuance process.This project is built using the
Zenroom ecosystem, incorporating Zencode natural language smart contracts
for secure, flexible, and human-readable protocol implementation.

---
<br><br>


## 🧱 Building blocks

### 🎫 Verifiable Credential issuer 

[OIDC4VCI REFERENCE](https://openid.github.io/OpenID4VCI/openid-4-verifiable-credential-issuance-wg-draft.html)

The credential issuer is the component that implements the endpoint to `issue` 
verifiable credentials in different formats (eg. w3c-vc, iso.18013-5 aka mDL)
actually it's agnostic to the format.

API for credential issuance is comprised of the following endpoints

**Mandatory**

```http
POST /credential
GET /.well-known/openid-credential-issuer
GET /.well-known/openid-configuration
```

**Optionals**

```http
GET /credential_offer
GET /authorize
POST /batch_credential
POST /token
POST /op/par
POST /as/par
```

Core concepts of the issuer:
 * Wallets can request one OR batch requests for one OR multiple credentials
   with the same access token
 * Credentials can be issued syncronously or deferred
 * Multiple key proof types are supported
 * The same OAuth 2.0 Authorization Server can protect one or more Credential
   Issuers. Wallets determine the Credential Issuer's Authorization Server
   using the Credential Issuer's metadata


### 🚦 Authorization Server OAuth 2.0 

[REFERENCE RFC6749](https://www.rfc-editor.org/rfc/rfc6749.txt)

Credential Issuers use OAuth 2.0 RFC6749 Authorization Server for access.
A single server can protect multiple Issuers, identified via metadata (/.well-known/openid-credential-issuer).
All OAuth 2.0 Grant Types and extensions work with the credential issuance API. Unspecified aspects follow [@!RFC6749].
Some tweaks and enhancements are needed although, this extensions include:

- **New Authorization Details Type - `openid_credential`:**
  - Conveys Credential details Wallet aims to obtain (see [#authorization-details](https://openid.github.io/OpenID4VCI/openid-4-verifiable-credential-issuance-wg-draft.html#authorization-details)).

- **New Token Response Error Codes:**
  - `authorization_pending` and `slow_down` support deferred authorization for Pre-Authorized Code grant type.

- **Client Metadata:**
  - Uses client metadata, introducing `credential_offer_endpoint` for Wallet to publish its Credential Offer Endpoint (see [#client-metadata](https://openid.github.io/OpenID4VCI/openid-4-verifiable-credential-issuance-wg-draft.html#client-metadata)).

- **Authorization Endpoint Enhancements:**
  - Adds `issuer_state` for issuer-initiated Credential Offer processing (see [#credential-authz-request](https://openid.github.io/OpenID4VCI/openid-4-verifiable-credential-issuance-wg-draft.html#credential-authz-request)).
  - Introduces `wallet_issuer` and `user_hint` for Credential Issuers to request Verifiable Presentations during Authorization Request.

- **Token Endpoint Enhancements:**
  - Adds optional response parameters - `c_nonce` and `c_nonce_expires_in` - for nonce-based proof of possession of key material (see [#token-response](https://openid.github.io/OpenID4VCI/openid-4-verifiable-credential-issuance-wg-draft.html#token-response)).

For details, refer to the full specification.





<br>

<div id="toc">

### 🚩 Table of Contents

- [🎮 Quick start](#-quick-start)
- [🚑 Community & support](#-community--support)
- [🐋 Docker](#-docker)
- [🐝 API](#-api)
- [🔧 Configuration](#-configuration)
- [📋 Testing](#-testing)
- [🐛 Troubleshooting & debugging](#-troubleshooting--debugging)
- [😍 Acknowledgements](#-acknowledgements)
- [👤 Contributing](#-contributing)
- [💼 License](#-license)

</div>

***
## 🎮 Quick start

To start using all the components run the following command in the root folder

```bash
make
```

Then point your browser to the [http://localhost:3000/docs](http://localhost:3000/docs) to see all the exposed endpoints


## 🐋 Docker
You can start it using docker, just have to mount you static file directory
```
docker pull ghcr.io/forkbombeu/didroom_microservices:latest
docker run -p 3000:3000 -v public:/app/public ghcr.io/forkbombeu/didroom_microservices:latest
```

**[🔝 back to top](#toc)**

***
## 🚑 Community & support

**[📝 Documentation](#toc)** - Getting started and more.

**[🌱 Ecosystem](https://forkbomb.solutions/solution/didroom/)** - W3C-DID Dyne, Signroom, Zenroom, Didroom

**[🚩 Issues](../../issues)** - Bugs end errors you encounter using {project_name}.

**[[] Matrix](https://socials.dyne.org/matrix)** - Hanging out with the community.

**[🗣️ Discord](https://socials.dyne.org/discord)** - Hanging out with the community.

**[🪁 Telegram](https://socials.dyne.org/telegram)** - Hanging out with the community.

**[🔝 back to top](#toc)**

***
## 🐋 Docker

Please refer to [DOCKER PACKAGES](../../packages)


**[🔝 back to top](#toc)**

***
## 🐝 API

Available endpoints, TBD

<!--
### POST /token

Execute a transaction with some amount

**Parameters**

|          Name | Required |  Type   | Description       | 
| -------------:|:--------:|:-------:| ------------------|
|       `token` | required | string  | Type of token. Accepted values `idea` or `strength`  |
|       `amount`| required | number  | Transaction's token amount |
|       `owner` | required | ULID    | The ULID of the Agent's owner |
 
### GET /token/${request.token}/${request.owner}

Retrieves the actual value of the token type for the specified owner
-->

**[🔝 back to top](#toc)**

***
## 🔧 Configuration

TBD

**[🔝 back to top](#toc)**

***

## 📋 Testing

TBD

**[🔝 back to top](#toc)**

***
## 🐛 Troubleshooting & debugging

TBD

**[🔝 back to top](#toc)**

***
## 😍 Acknowledgements

Copyleft 🄯 2023 by [Forkbomb](https://www.forkbomb.eu) BV, Amsterdam

Designed, written and maintained by Puria Nafisi Azizi, Andrea D'Intino, Alberto Lerda with contributions of Matteo Cristino.

**[🔝 back to top](#toc)**

***
## 👤 Contributing

Please first take a look at the our [Contributor License Agreement](CONTRIBUTING.md) then

1.  🔀 [FORK IT](../../fork)
2.  Create your feature branch `git checkout -b feature/branch`
3.  Commit your changes `git commit -am 'feat: New feature\ncloses #398'`
4.  Push to the branch `git push origin feature/branch`
5.  Create a new Pull Request `gh pr create -f`
6.  🙏 Thank you


**[🔝 back to top](#toc)**

***
## 💼 License
    Didroom standalone microservices
    Copyleft 🄯 2023 Forkbomb BV, Amsterdam

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as
    published by the Free Software Foundation, either version 3 of the
    License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

**[🔝 back to top](#toc)**
