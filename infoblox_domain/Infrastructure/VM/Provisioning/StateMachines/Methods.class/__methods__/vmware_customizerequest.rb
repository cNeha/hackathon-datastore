#
# Description: This method is used to Customize the VMware and VMware PXE Provisioning Request
#

# Get provisioning object
prov = $evm.root["miq_provision"]

$evm.log("info", "Provisioning ID:<#{prov.id}> Provision Request ID:<#{prov.miq_provision_request.id}> Provision Type: <#{prov.provision_type}>")
unique_check = prov.options[:miq_force_unique_name]
$evm.log(:info, "THE OPTION FOR MIQ FORCE UNIQUE NAME IS #{unique_check}")
prov.set_option(:miq_force_unique_name, false)
