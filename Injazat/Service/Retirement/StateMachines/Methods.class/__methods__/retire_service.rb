# Remove zone from /var/www/miq/vmdb/app/models/mixins/retirement_mixin.rb for master

require 'rest-client'
require 'json'
require "base64"


@cfme_user = $evm.object['cfme_user']
@cfme_password = $evm.object.decrypt('cfme_password')

def retire_vm(ip_address, vm_id)
  post_params = {
    "action" => "retire"
  }

  api_uri = "https://#{ip_address}/api"
  url = URI.encode(api_uri + '/auth')
  rest_return = RestClient::Request.execute(
                            :method => "get",
                            :url =>        url,
                            :user       => @cfme_user,
                            :password   => @cfme_password,
                            :headers    => {:accept => :json},
                            :verify_ssl => false)
  auth_token = JSON.parse(rest_return)['auth_token']

  url = URI.encode(api_uri + '/vms/' + vm_id.to_s)
  rest_return = RestClient::Request.execute(
                            :method =>     "post",
                            :url =>        url,
                            :headers    => {:accept        => :json,
                                            'x-auth-token' => auth_token},
                            :payload    => post_params.to_json,
                            :verify_ssl => false)

end

def get_miq_server_ip(vm)
  zone_id = vm.ext_management_system.zone_id
  ip = $evm.vmdb(:miq_server).where(:zone_id => zone_id).first.ipaddress
end

$evm.root['service'].vms.each do |vm|
    next if vm.ext_management_system.nil?
    ip_address = get_miq_server_ip(vm)
    retire_vm(ip_address, vm.id)
end
