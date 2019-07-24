#Test
#require 'base64'
require 'rest-client'
 
 # Set the request parameters
 host =  'https://acnaiop.service-now.com'
 user =  'cloud.form.admin'
 pwd =  'cloud.form.admin'
 #sys_id =  '4e8dfcfcdbcf1b0004819015ca961907'
 
  begin # Get the incident with sys_id declared above
   response = RestClient.get( "#{host}/api/now/table/sys_user?sysparm_limit=1t", :user => "#{user}",:password => "#{pwd}", :accept => 'application/json')
    #puts "#{response.to_str}" puts "Response status: #{response.code}"
   response. headers. each { |k,v | puts "Header: #{k}=#{v}" }
 
  rescue => e
    puts "ERROR: #{e}" 
  end
