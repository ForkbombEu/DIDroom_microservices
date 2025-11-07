Scenario 'http': call

Given I have a 'string dictionary' named 'offer'

When I create json escaped string of 'offer'
When I rename 'json escaped string' to 'credential offer'
When I set 'schema' to 'openid-credential-offer://' as 'string'
When I create url from 'schema'
When I append percent encoding of 'credential offer' as http request to 'url'

Then print the 'url'

Compute: store in file where path is 'deeplink_path', content is 'url'
