#
# Description: <Method description here>
#
  require 'base64'
  require 'rest-client'

  # https://rubygems.org/gems/json # Example install using gem #   gem install json require 'json'
  # https://rubygems.org/gems/rest-client # Example install using gem #   gem install rest-client require 'rest-client'

  # Set the request parameters
 host =  'https://spikebhp.service-now.com'
 user =  'cloudforms.integration'
 pwd =  'WelcomeCloudforms'

 request_body_map =  {
    :type => 'standard',
    :requested_by => 'subrat.behera1@bhp.com',
    :business_service => '265ee068db0353804eb473e9bf9619be',
    :cmdb_ci => '559477ecdbf92780e6984cf38a96196e',
    :risk => '4',
    :impact => '3',
    :u_impacted_locations => 'HoustonDC1',
    :assignment_group => 'b316b05ddb78a708dc2e6e314a96193d',
    :short_description => 'Created by ruby script1',
    :description => 'Created by ruby script1',
    :justification => 'justify',
    :implementation_plan => 'plan1',
    :risk_impact_analysis => 'test_risk',
    :u_impact_analysis => 'test',
    :backout_plan => 'test',
    :test_plan => 'test',
    :start_date => '2019-30-04 21:05:00',
    :end_date => '2019-30-04 23:05:00',
    :work_start => '2019-30-04 21:15:00',
    :work_end => '2019-30-04 22:05:00',
  }


  begin
   $evm.log(:info, "----- ServiceNow API calling REST -----")
   response = RestClient.post("#{host}/api/sn_sc/servicecatalog/items/fd7c7928db09330429d58a264a961992/submit_producer",request_body_map.to_json,{:authorization  => "Basic #{Base64.strict_encode64("#{user}:#{pwd}")}",:content_type => 'application/json',:accept => 'application/json'})
   puts "#{response.to_str}"
   $evm.log(:info, "----- Response code: #{response.code} -----")
   puts "Response status: #{response.code}"
   response.headers.each { |k,v| puts "Header: #{k}=#{v}" }
   json_parse = JSON.parse(response)
   $evm.log(:info, "----- Set result after parsing the json -----")
   result = json_parse['result']
   $evm.log(:info, "----- Sys_id after creating CR : #{result['sys_id']} -----")
   puts "snow_sysid : #{result['sys_id']}"
  rescue => e
    puts "ERROR: #{e}"

  end

