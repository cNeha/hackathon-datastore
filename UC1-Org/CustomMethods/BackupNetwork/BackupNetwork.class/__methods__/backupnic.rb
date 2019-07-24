#
# Description: <Method description here>
#
#
# Description: Add NICs to VM if a backup is required
#
# THIS NEEDS TO BE MODIFIED TO ALLOW FOR DYNAMIC OR USER DRIVEN NETWORK ALLOCATIONS
#
# Get a handle on the current provisioning
prov = $evm.root['miq_provision']

#Get the options that were passed through the service dialog
#backup_nic = prov.options[:backup_nic]
backup_nic = prov.options[:dialog_param_backup]
vmipaddress = prov.options[:vmipaddress]
vlan0 = prov.options[:vlan][1]
$evm.log("info", "BHP: VM: backup_nic: #{backup_nic}, IP Address: #{vmipaddress}, VLAN: #{vlan0}")

case prov.get_option(:st_prov_type)
  when "vmware"
    if backup_nic == "t"
      vlan1 = 'Management Network' #Needs to be the name of backup network of vmware.
    else
      vlan1 = 'Not set'
    end
    device_type = "VirtualVmxnet3"
    #device_type = "VirtualE1000"
  when "redhat"
    #vlan0 = 'ovirtmgmt'
    if backup_nic == "t"
      vlan1 = 'Backup_Network (Backup_Network)'
    else
      vlan1 = 'Not set'
    end
end
prov.set_option(:prod_net, vlan0)
prov.set_network_adapter(0, {:network => vlan0})
#prov.set_nic_settings(0, {:ip_addr => vmipaddress, :subnet_mask => "255.255.255.0", :gateway => "10.215.10.1", :dns_domain => "example.com", :dns_servers => "10.215.10.1"})
if backup_nic == "t"
  prov.set_option(:backup_net, vlan1)
  prov.set_network_adapter(1, {:network => vlan1})
  $evm.log("info", "BHP: Backup NIC requested: #{vlan1} ")
end
$evm.log("info", "BHP: Networks set to Vlan0: #{vlan0} and Vlan1: #{vlan1} ")
