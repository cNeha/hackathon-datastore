require 'rest_client'
require 'json'
require 'base64'
require 'uri'

server_url				= $evm.object['server_url']
ws_username             = $evm.object['ws_username']
ws_password             = $evm.object.decrypt('ws_password')
method					= :get
uri                     = "#{server_url}/api/now/table/cmdb_ci_business_app"

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
)

$evm.log(:info, "===ServiceNow API: calling rest")
response = request.execute
hash=JSON.parse(response)
data= hash["result"][0]["name"]
values = {}
values[nil] = "<Select>"
hash["result"].each { |x| values[x["name"]] = x["name"] }
$evm.object["values"]=values
