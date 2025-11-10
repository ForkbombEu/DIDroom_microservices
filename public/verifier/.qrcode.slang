Prepare 'res': connect to 'verifier_endpoint' and do post where object is 'object'

Given I have a 'string' in path 'res.result.qr_code'
Then print the 'qr_code'

Compute: store in file where path is 'qrcode_path', content is 'qr_code'
Compute: execute in shell where command is 'command'
