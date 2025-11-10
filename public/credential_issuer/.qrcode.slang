Scenario 'http': call

Given I have a 'string dictionary' named 'offer'

When I create json escaped string of 'offer'
When I rename 'json escaped string' to 'credential offer'
When I set 'schema' to 'openid-credential-offer://' as 'string'
When I create url from 'schema'
When I append percent encoding of 'credential offer' as http request to 'url'

Then print the 'url'

Compute 'qr_code': create qr code where text is 'url'
Compute: store in file where path is 'qrcode_path', content is 'qr_code'
Compute: execute in shell where command is 'command'
