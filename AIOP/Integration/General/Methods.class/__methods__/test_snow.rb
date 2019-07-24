require 'rest-client'
require 'json'
require 'base64'

def log(level, message)
  method = '----- Get ServiceNow CMDB Record -----'
  $evm.log(level, "#{method} - #{message}")
end

snow_server   = $evm.object['snow_server']
snow_user     = $evm.object['snow_user']
snow_password = $evm.object.decrypt('snow_password')
table_name    = $evm.object['table_name']
uri           = "https://#{snow_server}/api/now/table/sys_user?sysparm_limit=1t"

headers = {
  :content_type  => 'application/json',
  :accept        => 'application/json',
  :authorization => "Basic #{Base64.strict_encode64("#{snow_user}:#{snow_password}")}"
}
request = RestClient::Request.new(
  :method  => :get,
  :url     => uri,
  :headers => headers
)
rest_result = request.execute
log(:info, "Return code <#{rest_result.code}>")

json_parse = JSON.parse(rest_result)
result = json_parse['result']
log(:info, "Item <#{result['name']}> attributes:")
result.sort.each do | k, v |
  log(:info, "    #{k} => <#{v}>")
end

