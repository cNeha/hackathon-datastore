require 'rest-client'
require 'base64'
require 'uri'

server_url				= $evm.object['server_url']
ws_username             = $evm.object['ws_username']
ws_password             = $evm.object.decrypt('ws_password')
method					= $evm.object['method']
uri                     = "#{server_url}/#{$evm.object['uri']}"
$evm.object['result']	= ""

payload = $evm.object['payload'].nil? ? {} : JSON.parse($evm.object['payload'])
$evm.log(:info, "===Turbonomic API: calling rest\nendpoint: #{uri}")
$evm.log(:info, "===Turbonomic API: ===============Payload==================")
$evm.log(:info, "===Turbonomic API: #{payload.to_json}")
headers = {
  :content_type  => :json,
  :accept        => :json,
  :authorization => "Basic #{Base64.strict_encode64("#{ws_username}:#{ws_password}")}"
}

request = RestClient::Request.new(
  :method     => method,
  :url        => uri,
  :headers    => headers,
  :verify_ssl => false,
  :payload    => payload.to_json
)

response = request.execute
$evm.object['result'] = response.body
$evm.log(:info, "===Turbonomic API: Called rest uri: #{uri}")
$evm.log(:info, "===Turbonomic API: ===============Response==================")
$evm.log(:info, "===Turbonomic API: #{$evm.object['result'].to_json}")
exit MIQ_OK
