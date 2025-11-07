Prepare 'res': connect to 'verifier_endpoint' and do post where object is 'object'

Given I have a 'base64' part of path 'res.result.qr_code' after the string prefix 'data:image/png;base64,'
Then print the 'qr_code'

Compute: store in file where path is 'qrcode_path', content is 'qr_code'
Compute: execute in shell where command is 'command'

