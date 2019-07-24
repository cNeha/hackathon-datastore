#rails dev code for SNOW request creation

#bhelgeso [11:58]
#correct add them to the URL. I think we had to do that with AWS proxy connections at Vz as well
#[12:01]
#I did something like this so we could encrypt the password there:
#                                                               [12:01]
#proxy = “http://#{username}:#{aws_props.decrypt(‘password’)}@#{proxy}”
#$evm.log(:info, “proxy: #{proxy}“)
#    aws_client = Aws::EC2::Client.new(:region => region, :credentials => aws_creds, :http_proxy => proxy)
#
#[12:02]
#Don;t print the log comment as the password will show. Just for testing of course

# Alex Notes
#  Using the above example, and the docs at http://www.rubydoc.info/gems/rest-client/1.6.3/RestClient
#This should be something like:
#     RestClient.proxy = "https://#{proxy_user}:#{proxy_pass.decrypt}@#{proxy_address}"

# Modifying for Change Task/Change Request
# Table name and classes documentation:
#  https://docs.servicenow.com/bundle/jakarta-servicenow-platform/page/administer/reference-pages/reference/r_TablesAndClasses.html?title=Tables_and_Classes

#Requirements:
#parent sc_request  -  Save the sysid for this
#child  sc_req_item - add :parent and :request field, populate with the sysid from sc_request, save the sysid for this
#grand  sc_task     - add :parent and :request_item field, populate with the sysid from sc_req_item

#Table details per SNOW docs
#sc_request 	Request 	                task 	Task
#sc_req_item 	Requested Item 	task 	Task
#sc_task 	        Catalog Task 	        task 	Task


require 'Base64'
require 'rest-client'
require 'json'

def log(level, message)
  puts "#{message}"
end


def create_sc_request(snow_server, headers, short_description, assignment_group)
  table_name = 'sc_request'
  uri        = "https://#{snow_server}/api/now/table/#{table_name}"
  log(:info, "BHP: Creating Service Now Parent sc_request object")

  new_request = {
      :short_description              =>  short_description,
      :assignment_group               =>  assignment_group  }

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

def create_sc_req_item(snow_server, headers, short_description, assignment_group, sc_request_sysid)
  table_name = 'sc_req_item'
  uri        = "https://#{snow_server}/api/now/table/#{table_name}"
  log(:info, "BHP: Creating Service Now Child sc_req_item object")

  new_request = {
      :short_description              =>  short_description,
      :assignment_group               =>  assignment_group,
      :parent                         =>  sc_request_sysid,
      :request                        =>  sc_request_sysid
  }

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

def create_sc_task(snow_server, headers, short_description, assignment_group, sc_req_item_sysid)
  table_name = 'sc_task'
  uri        = "https://#{snow_server}/api/now/table/#{table_name}"
  log(:info, "BHP: Creating Service Now grandchild sc_task object")

  new_request = {
      :short_description              =>  short_description,
      :assignment_group               =>  assignment_group,
      :parent                         =>  sc_req_item_sysid,
      :request_item                   =>  sc_req_item_sysid
  }

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

begin
#Do we need a proxy server?
#  use_proxy = $evm.object['snow_use_proxy'] || false
  use_proxy = true
#  proxy_url = $evm.object['snow_proxy_url'] || nil
  proxy_url = "https://proxy.yourdomain.com"
  if use_proxy == true
    log(:info, "BHP: Proxy requirement is set to <#{use_proxy}>")
    if proxy_url
      log(:info, "BHP: Proxy url is set to <#{proxy_url}>")
      RestClient.proxy = proxy_url.to_s
    else
      log(:warn, "Proxy url is not set, but proxy requirement has been enabled")
    end
  end

  snow_server = 'yoursite.service-now.com'
  snow_user = 'username'
  snow_password = 'password'
  assignment_group = 'yourteam'
  short_description = 'Cloudforms Request Creation Test 001'
  headers = { :content_type => 'application/json', :accept => 'application/json', :authorization => "Basic #{Base64.strict_encode64("#{snow_user}:#{snow_password}")}"}

  sc_request_sysid = create_sc_request(snow_server, headers, short_description, assignment_group)
  puts "All done, the sc_request sysid is #{sc_request_sysid}"

  sc_req_item_sysid = create_sc_req_item(snow_server, headers, short_description, assignment_group, sc_request_sysid)
  puts "Created the sc_req_item object with a sysid of #{sc_req_item_sysid}"

  sc_task_sysid = create_sc_task(snow_server, headers, short_description, assignment_group, sc_req_item_sysid)
  puts "Created the sc_task object with a sysid of #{sc_req_item_sysid}"


end

