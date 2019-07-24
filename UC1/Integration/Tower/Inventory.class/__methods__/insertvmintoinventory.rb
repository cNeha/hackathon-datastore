#
# Description: Insert a VM into the Cloud-managed Inventory.  This method relies on the Organisation name being passed through.
# It also relies on two groups 
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
    results = JSON.parse(response.to_str)
end

# Get the VM handle
prov = $evm.root['miq_provision']
vm = prov.vm

# Put the server in the right Ansible inventory group
if vm.os_image_name == "windows_generic"
  $evm.log(:info, "BHP: This will be inserted into the Windows inventory group")
  groupname = "Windows"
else
  $evm.log(:info, "BHP: This will be inserted into the Linux inventory group")
  groupname = "Linux"
end

# Get userid, password, url and other stuff from CF. Pullin the organisation name
tower = $evm.vmdb(:ext_management_system).find_by_type("ManageIQ::Providers::AnsibleTower::AutomationManager")
tower_host = tower.url
$username = tower.authentication_userid
$password = tower.authentication_password
organisationname = $evm.object['orgid']

# Get the VM name, the target vendor and the IP address
vmname = prov.options[:vm_target_name]
vendor = prov.options[:st_prov_type]
vmipaddress = prov.options[:vmipaddress]   # This is from the IPAM GetIP method

$evm.log(:info, "BHP: Tower Host: #{tower_host}, VM IP Address: #{vmipaddress}, Group: #{groupname}, Organisation: #{organisationname}")

# Get the organisation ID from Tower based on the name passed through
url = tower_host + "organizations/"
tower_ret = do_rest(url, :get, JSON.generate({}))
tower_ret["results"].each do |organisation|
  if organisation["name"] == organisationname
    $orgid = organisation["id"]
  end
end

# Get the Group ID based on the name defined above
url = tower_host + "groups/"
tower_ret = do_rest(url, :get, JSON.generate({}))
tower_ret["results"].each do |group|
  if group["name"] == groupname
    $groupid = group["id"]
  end
end

# Set up the variables
url = tower_host + "groups/" + $groupid.to_s + "/hosts/"
description = "Owner: #{prov.userid}; Location: #{vendor}"

# Create the host in the VMware inventory
$evm.log(:info, "BHP: VM Name: #{vmname}, Description: #{description}, URL: #{url}")
tower_ret = do_rest(url, :post, JSON.generate({"name"                  =>vmname,
                              "description"           =>description,
                              "organization"          =>$orgid.to_s,
                              "variables"             =>"",
  }))

# Grab the host ID of the VM we just created so that we can assign the IP address
host_id = tower_ret["id"]
url = tower_host + "hosts/" + host_id.to_s + "/variable_data/"

# Set the IP address
$evm.log(:info, "BHP: Host ID: #{host_id}, IP Address: #{vmipaddress}, URL: #{url}")
do_rest(url, :put, JSON.generate({"ansible_ssh_host"  =>vmipaddress}))
