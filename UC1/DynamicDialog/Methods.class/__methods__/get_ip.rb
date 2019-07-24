#
# Description: <Method description here>
#
#cc_vm_name = "BijoyT3"
$evm.log(:info, "BijoyT3")
cc_vm_name = $evm.root['dialog_param_vm_list']
$evm.log(:info, ": #{cc_vm_name}")
list_values = {
  'required'   => false,
  'protected'  => false,
}
value=""
if cc_vm_name != ""
  $evm.object['visible'] = true
else
  $evm.object['visible'] = false
end
list_values.each do |key, value|
  $evm.object[key] = value
end
#dialog_field = $evm.object
#$evm.vmdb('vm').all.each { |x| if x.name == cc_vm_name then value= x.ipaddresses[0] end}
$evm.vmdb('vm').all.each { |x| if x.name == cc_vm_name then value= x.power_state end}
$evm.log(:info, ": #{value}")
$evm.object['value']=value
