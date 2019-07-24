#
# Description: <Method description here>
#
require 'rest_client'
require 'json'
require 'base64'
require 'uri'

sys_id					= $evm.object['sys_id'] || nil
query					= $evm.object['query'] || nil
method					= :post
snow_server             = $evm.object['snow_server']
snow_user               = $evm.object['snow_user']
snow_password           = $evm.object['snow_password']
table_name              = $evm.object['table_name']
user                    = $evm.root['user'] 
type                    = 'Standard'
requested_by            = user.name
business_service        = $evm.root['dialog_snow_app_name_box']
cmdb_ci                 = 'test'
risk                    = 'Low'
impact                  = 'Low-3'
u_impacted_locations    = 'Test'
assignment_group        = 'CMP Development & support'
short_description       = 'Test Change Request'
description             = 'Test Change Request'
justification           = 'Test Change Request'
implementation_plan     = 'Test Change Request'
risk_impact_analysis    = 'Test Change Request'
backout_plan            = 'Test Change Request'
test_plan               = 'Test Change Request'
start_date              = '2019-05-09 11:14:37'
end_date                = '2019-05-09 21:14:37'
work_start              = '2019-05-09 11:14:37'
work_end                = '2019-05-09 21:14:37'

#uri                     = "https://#{snow_server}/api/now/table/#{table_name}"
uri                     = "https://spikebhp.service-now.com/api/now/table/change_request"

unless sys_id.nil?
  uri << "/#{sys_id}" 
end

unless query.nil?
  uri << "?#{JSON.parse(query).to_param}"
end

#$evm.object['result']	= ""

#payload = $evm.object['payload'].nil? ? {} : JSON.parse($evm.object['payload']) rescue {}
$evm.log(:info, "===ServiceNow API: uri: #{uri}   -  method: #{method}")
#$evm.log(:info, "===ServiceNow API: payload: #{payload.inspect}")

body = {
	  :type                           =>  type,
      :requested_by                   =>  requested_by,
      :business_service               =>  business_service,
      :cmdb_ci                        =>  cmdb_ci,
      :risk                           =>  risk,
      :impact                         =>  impact,
	  :u_impacted_locations           =>  u_impacted_locations,
      :assignment_group               =>  assignment_group,
	  :short_description              =>  short_description,
      :description                    =>  description,
      :justification                  =>  justification,
      :implementation_plan            =>  implementation_plan,
      :risk_impact_analysis           =>  risk_impact_analysis,
      :backout_plan                   =>  backout_plan,
	  :test_plan                      =>  test_plan,
      :start_date                     =>  start_date,
      :end_date                       =>  implementation_plan,
      :work_start                     =>  backout_plan,
      :work_end                       =>  work_end 
}

headers = {
  :content_type  => :json,
  :accept        => :json,
  :authorization => "Basic #{Base64.strict_encode64("#{snow_user}:#{snow_password}")}"
}
$evm.log(:info, "BHP: Creating Service Now Change Request")
request = RestClient::Request.new(
  :method     => method,
  :url        => uri,
  :headers    => headers,
  :verify_ssl => false,
  :body       => body
)

$evm.log(:info, "===ServiceNow API: calling rest")
rest_result = request.execute
$evm.log(:info, "BHP: Return code: #{rest_result.code}")
json_parse = JSON.parse(rest_result)
$evm.log(:info, "BHP: Set Results: <#{json_parse['result']}>")
result = json_parse['result']

  # Need to account for empty results.
  puts "Finished setting result"
  if result.first.nil?
    $evm.log(:info, "BHP: No reply was received for the request")
    return false
  else
    $evm.log(:info, "BHP: sys_id => <#{result['sys_id']}>")
    # Add sys_id to VM object
    #  vm.custom_set(:servicenow_sys_id, result.first['sys_id']) unless result.first['sys_id'].nil?
    $evm.log(:info, "BHP: Assigned Sys_ID: <#{result['sys_id']}> Full Rest Response:")
    result.sort.each do |k,v|
      $evm.log(:info, "BHP:     #{k} => <#{v}>")
    end
    return "#{result['sys_id']}"
  end


