#
# Description: This method is used to apply PreProvision customizations for VMware
#

# Get provisioning object
prov = $evm.root['miq_provision']

$evm.log("info", "Provisioning ID:<#{prov.id}> Provision Request ID:<#{prov.miq_provision_request.id}> Provision Type: <#{prov.provision_type}>")
$evm.log("info", "======================================================")
template = prov.get_option(:dialog_template)
$evm.log(:info, "Template Details are #{template}")
prov.set_option(:src_vm_id, template)

