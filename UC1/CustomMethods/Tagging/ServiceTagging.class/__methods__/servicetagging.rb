#
# Tag the service
#

#$evm.instantiate('/Discovery/ObjectWalker/object_walker')
# Get initial info
service_template_provision_task = $evm.root['service_template_provision_task']
the_service = service_template_provision_task.destination
protection = $evm.root['dialog_option_0_retirement_protect']
$evm.log(:info, "BHP: Tagging service: #{the_service.name}, Protect? #{protection}")

# Tag for VM delete protection
if protection == "t"
  the_service.tag_assign("vm_protect/retirement_protect")
  $evm.log('info', "BHP: Service: #{the_service.name} protected from retirement")
else
  the_service.tag_assign("lifecycle/retire_full")
  $evm.log('info', "BHP: VM NAME: #{the_service.name} setting full retirement when retired")
end

