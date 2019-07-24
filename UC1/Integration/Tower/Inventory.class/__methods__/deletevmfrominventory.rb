#
# Description: Remove a VM into the VMware Inventory
#

require 'rest-client'
require 'json'

def do_rest(the_url, func, json_data)
    response = RestClient::Request.new(
        :verify_ssl => false,
        :method => func,
        :url => the_url,
        :user => $username,
        :password => $password,
        :headers => { :accept => :json,
        :content_type => :json},
        :payload => json_data
    ).execute
    if response == ""
      $evm.log(:info, "BHP: Nothing returned from REST call. All good.")
    else
      results = JSON.parse(response.to_str)
    end
end

# To get the VM handle, we need to figure out how we've been called
case $evm.root['vmdb_object_type']
  when 'miq_provision'                # called from a VM provision workflow
    vm = $evm.root['miq_provision'].destination
  when 'vm'
    vm = $evm.root['vm']              # called from a button
  when 'vm_retire_task'
    task = $evm.root['vm_retire_task']              # a retirement
    vmid = task.options[:src_ids]
    vm = $evm.vmdb(:vm).find_by(:id => vmid)
  when 'automation_task'              # called from a RESTful automation request, vm_id is a passed parameter
    attrs = $evm.root['automation_task'].options[:attrs]
    vm_id = attrs[:vm_id]
    vm = $evm.vmdb('vm').find_by_id(vm_id)
end

# Get password and other stuff from model else set it here
tower = $evm.vmdb(:ext_management_system).find_by_type("ManageIQ::Providers::AnsibleTower::AutomationManager")
tower_host = tower.url
$username = tower.authentication_userid
$password = tower.authentication_password
vmname = vm.name
$evm.log(:info, "BHP: Tower Host: #{tower_host}, VM Name: #{vmname}")

# Create the host in the VMware inventory
url = tower_host + "hosts?search=" + vmname
$evm.log(:info, "BHP: VM Name: #{vmname}, URL: #{url}")
tower_ret = do_rest(url, :get, JSON.generate({"name" =>vmname }))

if tower_ret["count"] != 0
  results = tower_ret["results"]
  host_id = results[0]["id"]
  url = tower_host + "hosts/" + host_id.to_s + "/"

  # Delete the VM from Ansible Inventory
  $evm.log(:info, "BHP: Host ID: #{host_id}, URL: #{url}")
  tower_ret = do_rest(url, :delete, "")
else
  $evm.log(:info, "BHP: The VM is already removed. All good!")
end  

