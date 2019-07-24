#
# Description: The API has written the new IP address to the evm.object as "ipaddr" we need to write it out and put it in the provisioning dialog.
# If Infoblox writes any other values (VLAN, netmask, gateway, etc) we need to write it here
#
$evm.log(info: "BHP: Writing IP address to dialog")
prov = $evm.root['miq_provision']
ipaddress = $evm.object['ipaddr']
prov.set_option(:vmipaddress, ipaddress)
