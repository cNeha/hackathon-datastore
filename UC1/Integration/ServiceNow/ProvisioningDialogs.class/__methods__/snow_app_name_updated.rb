#
# Description: <Method description here>
#
app_type = $evm.root['dialog_radio_button_app_type']
$evm.log(:info, "BHP: App Type : #{app_type}")
$evm.object['required'] = false 
$evm.object['protected'] = false 
$evm.object['read_only'] = false
value=""
if app_type != "<Choose>" and app_type != "Existing"
  $evm.object['visible'] = false
else
  $evm.object['visible'] = true  
  #$evm.object['default_value'] = "<Select>"
require 'rest_client'
require 'json'
require 'base64'
require 'uri'

server_url				= $evm.object['server_url']
ws_username             = $evm.object['ws_username']
ws_password             = $evm.object.decrypt('ws_password')
method					= :get
sys_id					= $evm.object['sys_id'] || nil
query					= $evm.object['query'] || nil
uri                     = "#{server_url}/api/now/table/cmdb_ci_business_app?sysparm_fields=name%2Cowned_by%2Cit_application_owner"

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
#$evm.log(:info, "===ServiceNow API payload: #{$evm.object['result'].inspect}")
#$evm.log(:info, "===ServiceNow API payload: #{response}")
hash=JSON.parse(response)
data= hash["result"][0]["name"]
#hash["result"].each { |x| $evm.log(:info,  "============= #{x["name"]}") }
values = {}
values[nil] = "<Select>"
hash["result"].each { |x| values[x["name"]] = x["name"] }
$evm.object["values"]=values

end
