#Stop VM
cc_vm_name = $evm.root['dialog_dropdown_list_1']
cc_vm_action = $evm.root['dialog_commandcontrol_box']
$evm.log(:info, ": #{cc_vm_name}")
$evm.log(:info, ": #{cc_vm_action}")
#dialog_field = $evm.object
#$evm.vmdb('vm').all.each { |x| if x.name == cc_vm_name and cc_vm_action == 'Stop' then x.stop unless vm.nil? || vm.attributes['power_state'] == 'off'}
$evm.vmdb('vm').all.each { |x| vm = x.power_state}
$evm.log(:info, ": #{vm}")
