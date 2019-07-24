require 'rest_client'
require 'json'
require 'base64'
require 'uri'

server_url				= $evm.object['server_url']
ws_username             = $evm.object['ws_username']
ws_password             = $evm.object.decrypt('ws_password')
method					= $evm.object['method']
sys_id					= $evm.object['sys_id'] || nil
query					= $evm.object['query'] || nil
uri                     = "#{server_url}/api/now/table/#{$evm.object['table_name']}"

unless sys_id.nil?
  uri << "/#{sys_id}" 
end

unless query.nil?
  uri << "?#{JSON.parse(query).to_param}"
end

$evm.object['result']	= ""

payload = $evm.object['payload'].nil? ? {} : JSON.parse($evm.object['payload']) rescue {}
$evm.log(:info, "===ServiceNow API: uri: #{uri}   -  method: #{method}")
$evm.log(:info, "===ServiceNow API: payload: #{payload.inspect}")


headers = {
  :content_type  => :json,
  :accept        => :json,
  :authorization => "Basic #{Base64.strict_encode64("#{ws_username}:#{ws_password}")}"
}

#RestClient.proxy = $evm.object['proxy_url'] unless $evm.object['proxy_url'].nil?
request = RestClient::Request.new(
  :method     => method,
  :url        => uri,
  :headers    => headers,
  :verify_ssl => false,
  :payload    => payload.to_json
)

$evm.log(:info, "===ServiceNow API: calling rest")
response = request.execute
$evm.object['result'] = response.body
$evm.log(:info, "===ServiceNow API payload: #{$evm.object['result'].inspect}")
