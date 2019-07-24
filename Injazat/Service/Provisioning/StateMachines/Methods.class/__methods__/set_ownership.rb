def yaml_data(task, option)
  task.get_option(option).nil? ? nil : YAML.load(task.get_option(option))
end

def set_service_ownership(service, owner, group)
  service.owner = owner
  service.group = group
end

require 'rest-client'
require 'json'
require "base64"


@cfme_user = $evm.object['cfme_user']
@cfme_password = $evm.object.decrypt('cfme_password')

def set_vm_owner(group_description, vm_id)
  post_params = {
    "action" => "set_ownership",
    "resource" => {
      "group" => { "description" => group_description }
    }
  }

  api_uri = "https://localhost/api"
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


task = $evm.root['service_template_provision_task']
dialog_options = yaml_data(task, :parsed_dialog_options)
dialog_options = dialog_options[0] if !dialog_options[0].nil?
owner = $evm.root['user']
group = $evm.vmdb('miq_group').find_by(:description =>"#{dialog_options[:tenant]}-admins")
set_service_ownership(task.destination, owner, group)

prov_ids = task.get_option(:provision_request_ids)

prov_ids.values.each do |prov_id|
  provision_request = $evm.vmdb(:miq_request).find_by_id(prov_id)
  vm_name = provision_request.options[:vm_name]
  vm = $evm.vmdb(:vm).find_by_name(vm_name)
  $evm.log(:info, "setting vm_owner_group to #{group.description}")
  set_vm_owner(group.description, vm.id)
end
