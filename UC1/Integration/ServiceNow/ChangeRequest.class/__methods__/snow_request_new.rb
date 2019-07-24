#rails dev code for SNOW Change request creation
#Few parameters are hard coded, need to update

require 'rest_client'
require 'json'
require 'base64'
require 'uri'

def log(level, message)
  puts "#{message}"
end


def create_sc_request(snow_server, headers, short_description, assignment_group)
  table_name = 'change_request'
  uri        = "https://#{snow_server}/api/now/table/#{table_name}"
  log(:info, "BHP: Creating Service Now Change Request")

  new_request = {
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
      :work_end                       =>  work_end }

  request = RestClient::Request.new(
      :method  => :post,
      :url     => uri,
      :headers => headers,
      :payload => new_request.to_json
  )

  rest_result = request.execute
  log(:info, "BHP: Return code <#{rest_result.code}>")

  log(:info, "BHP: Begin json_parse <#{rest_result}> Class: <#{rest_result.class}")
  json_parse = JSON.parse(rest_result)
  log(:info, "BHP: Set Results: <#{json_parse['result']}>")
  result = json_parse['result']
  # Need to account for empty results.
  puts "Finished setting result"
  if result.first.nil?
    log(:info, "BHP: No reply was received for the request")
    return false
  else
    log(:info, "BHP: sys_id => <#{result['sys_id']}>")
    # Add sys_id to VM object
    #  vm.custom_set(:servicenow_sys_id, result.first['sys_id']) unless result.first['sys_id'].nil?
    log(:info, "BHP: Assigned Sys_ID: <#{result['sys_id']}> Full Rest Response:")
    result.sort.each do |k,v|
      log(:info, "BHP:     #{k} => <#{v}>")
    end
    return "#{result['sys_id']}"
  end
end


  snow_server = $evm.object['snow_server']
  snow_user = $evm.object['snow_user']
  snow_password = $evm.object['snow_password']
  user = $evm.root['user'] 
  type = 'Standard'
  requested_by = user.name
  business_service = $evm.root['dialog_snow_app_name_box']
  cmdb_ci = 'test'
  risk = 'Low'
  impact = 'Low-3'
  u_impacted_locations = 'Test'
  assignment_group = 'CMP Development & support'
  short_description = 'Test Change Request'
  description = 'Test Change Request'
  justification = 'Test Change Request'
  implementation_plan = 'Test Change Request'
  risk_impact_analysis = 'Test Change Request'
  backout_plan = 'Test Change Request'
  test_plan = 'Test Change Request'
  start_date = '2019-05-09 11:14:37'
  end_date = '2019-05-09 21:14:37'
  work_start = '2019-05-09 11:14:37'
  work_end = '2019-05-09 21:14:37'

  headers = { :content_type => 'application/json', :accept => 'application/json', :authorization => "Basic #{Base64.strict_encode64("#{snow_user}:#{snow_password}")}"}

  sc_request_sysid = create_sc_request(snow_server, headers, short_description, assignment_group)
  puts "All done, the sc_request sysid is #{sc_request_sysid}"



