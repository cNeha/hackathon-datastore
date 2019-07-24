require 'rest-client'
require 'json'
require 'uri'


def create_automation_request_api(ip, post_params)
  user = $evm.root['user']
  passwd = user.password
  api_uri = "https://#{ip}/api"
  url = URI.encode(api_uri + '/auth')
  rest_return = RestClient::Request.execute(
    :method => "get",
    :url => url,
    :user => user,
    :password => passwd,
    :headers => {:accept => :json},
    :verify_ssl => false
  )
  auth_token = JSON.parse(rest_return)['auth_token']
  puts "Auth Token is #{auth_token}"
  url = URI.encode(api_uri + '/automation_requests')
  rest_return = RestClient::Request.execute(
    :method => "post",
    :url => url,
    :headers => {
      :accept => :json,
      'x-auth-token' => auth_token
    },
    :payload => post_params,
    :verify_ssl => false
  )
#  result = JSON.parse(rest_return)
  puts "Result is #{rest_return}"
  return rest_return
  # return result['results'][0]['id']
end

#Method begins here
begin
post_params =  {
    :version => "1.1",
    :uri_parts => {
     :namespace => "testNS",
      :class => "Methods",
      :instance => "hello",
      :message => "create"
    },
    :requester => {
      :user_name => "admin",
      :auto_approve => false  #<=== here, auto_approve is set to false so that administrator can manually approve/deny the request
    }
}.to_json
puts post_params
create_automation_request_api("10.74.130.255", post_params) #<=== here you need to provide the IP address of cloudforms where your method resides
end

