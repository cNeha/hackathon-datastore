#
# Description: Method to get Business Owner
#
app_name = $evm.root['dialog_snow_app_name_box']

$evm.object['required'] = false 
$evm.object['protected'] = false 
$evm.object['read_only'] = true
value=""
if app_name != "" and app_name != "<Select>"
  $evm.object['visible'] = true


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
$evm.log(:info, "BHP: ServiceNow API: uri: #{uri}   -  method: #{method}")
$evm.log(:info, "BHP: ServiceNow API: payload: #{payload.inspect}")


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

$evm.log(:info, "BHP: ServiceNow API: calling rest")
response = request.execute
#$evm.object['result'] = response.body
#$evm.log(:info, "BHP: ServiceNow API payload: #{response}")
hash=JSON.parse(response)
#app_name = $evm.root['dialog_snow_app_name_box']
hash["result"].each { |x| if x["name"] == app_name then sys_id= x["owned_by"]["value"] end}
$evm.log(:info, "BHP: ServiceNow API payload: SysID: #{sys_id}")
#API Call to get Business Owner
uri1                    = "#{server_url}/api/now/table/sys_user/#{sys_id}"
request1 = RestClient::Request.new(
  :method     => method,
  :url        => uri1,
  :headers    => headers,
  :verify_ssl => false,
  :payload    => payload.to_json
)

$evm.log(:info, "BHP: ServiceNow API: calling rest")
response1 = request1.execute
#$evm.object['result'] = response1.body
#$evm.log(:info, "BHP: ServiceNow API payload: #{response1}")
hash=JSON.parse(response1)
data = hash["result"]["name"]
$evm.log(:info, "BHP: ServiceNow API payload: Business Owner Owner: #{data}")
values = {}
#values[nil] = "<Select>"
$evm.object["value"]=data

else
  $evm.object['visible'] = false
end
