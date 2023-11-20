# The prototype of the authz server

1. receives requests from the wallet app
  a. with a firebase access token (needed to notify the wallet app)
  b. with the name/id of the credential
  c. saves the data on redis in a queue, and saves the ts of the reqest/execution
  d. generate the access_token for the oauth flux used by the credential issuer
2. decides is the wallet app can have a credential (yes/no/maybe yes)
3. send back to wallet instnce the access token to initialize the oAuth flow with the credential issuer


