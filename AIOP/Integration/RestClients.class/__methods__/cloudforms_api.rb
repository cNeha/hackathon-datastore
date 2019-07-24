require 'rest-client'
require 'base64'
require 'uri'

server_url				= $evm.object['server_url']
ws_username             = $evm.object['ws_username']
ws_password             = $evm.object.decrypt('ws_password')
method					= $evm.object['method']
uri                     = "#{$evm.object['server_url']}/#{$evm.object['uri']}"
$evm.object['result']	= ""

unless $evm.object['turbonomic_filter'].nil?
  uri << "&filter[]=custom_attributes.name=turbonomic_actionType"
end

payload = $evm.object['payload'].nil? ? {} : $evm.object['payload']

$evm.log(:info, "---CloudForms API: calling rest")
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
$evm.log(:info, "---CloudForms API: rest result: #{$evm.object['result']}")

exit MIQ_OK
