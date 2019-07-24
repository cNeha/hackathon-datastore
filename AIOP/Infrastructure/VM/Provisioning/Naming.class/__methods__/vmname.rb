# Description: vmname
#
# Author: Kevin Morey <kmorey@redhat.com>
# License: GPL v3
#
# 1. If VM Name was not chosen during dialog processing then use vm_prefix from dialog
# else use model and [:environment] option to generate name
# 2. Use the template product to help generate a name
# 3. Then add 3 digit suffix to vm_name
#
# Example - When provisioning a RHEL vm with the environment option 'dev' chosen will generate a name like: cfmedevr01
# Example - When provisioning a Windows vm with the environment option 'test' chosen will generate a name like: cfmetstw01
# Example - When provisioning a Windows vm with no environment option chosen will generate a name like: cfmew01

$evm.log("info", "BHP: Detected vmdb_object_type: #{$evm.root['vmdb_object_type']}")

prov = $evm.root['miq_provision_request'] || $evm.root['miq_provision'] || $evm.root['miq_provision_request_template']

vm_name = prov.get_option(:vm_name).to_s.strip
number_of_vms_being_provisioned = prov.get_option(:number_of_vms)
dialog_vm_prefix = prov.get_option(:vm_prefix).to_s.strip

product  = prov.vm_template.operating_system['product_name'].downcase rescue 'other'

if product.include?('red hat')
  os_prefix = 'r'
elsif product.include?('suse')
  os_prefix = 's'
elsif product.include?('windows')
  os_prefix = 'w'
elsif product.include?('other') 
  os_prefix = 'o'  
elsif product.include?('linux')
  os_prefix = 'l'
else
  os_prefix = nil
end
$evm.log('info', "BHP: vm_name: #{vm_name} template: #{prov.vm_template.name} product: #{product} os_prefix: #{os_prefix}")

# If no VM name was chosen during dialog
if vm_name.blank? || vm_name == 'changeme'
  vm_prefix = nil
  vm_prefix ||= $evm.object['vm_prefix']
  $evm.log("info", "BHP: vm_name from dialog: #{vm_name.inspect} vm_prefix from dialog: #{dialog_vm_prefix.inspect} vm_prefix from model: #{vm_prefix.inspect}")

  # Get Provisioning options for VM Name
  #environment = prov.miq_request.options[:dialog]["dialog_param_Environment"]
  environment = prov.miq_request.options[:dialog]["dialog_tag_0_bhp_environment"]
  application = prov.miq_request.options[:dialog]["dialog_snow_app_name_box"]
  app = application[0..2].downcase
  $evm.log("info", "BHP: Environment: #{environment}, Application: #{application}, TLA: #{app}")

  
  # Set a Prefix for VM Naming
  dialog_vm_prefix.blank? ? vm_name = $evm.object['vm_prefix'] : vm_name = dialog_vm_prefix

  $evm.log("info", "BHP: VM Naming Prefix: #{vm_name}")

  # case environment option
  case environment
  when 'test'
    env_name = 't'
  when 'production'
    env_name = 'p'
  when 'development'
    env_name = 'd'
  when 'qa'
    env_name = 'q'
  else
    env_name = nil
  end
  #derived_name = "#{vm_name}0#{env_name}#{app}#{os_prefix}$n{2}"
  derived_name = "#{vm_name}0#{env_name}#{app}$n{2}"
else
  if number_of_vms_being_provisioned == 1
    derived_name = "#{vm_name}"
  else
    derived_name = "#{vm_name}$n{2}"
  end
end

$evm.object['vmname'] = derived_name
$evm.log("info", "BHP: VM Name: #{derived_name}")
