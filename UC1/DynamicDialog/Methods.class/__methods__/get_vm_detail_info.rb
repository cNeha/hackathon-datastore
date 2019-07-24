#
#            Automate Method for Selected VM Detail Info
#

$evm.log(:info, "BHP: vm_name:Test -------------")
cc_vm_name = $evm.root['dialog_vm_name']
#cc_vm_name = "BijoyT3"

# Checking If no VM name was chosen or VM Name dint pick
$evm.log(:info, "BHP: vm_name: #{cc_vm_name}")

list_values = {
  'required'   => false,
  'protected'  => false,
}

value = ""
p_status = ""
p_ip = ""
p_env = ""


if cc_vm_name != ""
  $evm.object['visible'] = true
else
  $evm.object['visible'] = false
end

list_values.each do |key, value|
  $evm.object[key] = value
end

#dialog_field = $evm.object
$evm.vmdb('vm').all.each { |x| if x.name == cc_vm_name then p_status = x.power_state end}
$evm.vmdb('vm').all.each { |x| if x.name == cc_vm_name then p_ip = x.ipaddresses[0] end}

# set options on De-Provisioning object
$evm.log(:info, "BHP: ----------------")
$evm.log(:info, "BHP: GetVM Info --> VM Name = #{cc_vm_name}")
$evm.log(:info, "BHP: GetVM Info --> IP Address =  #{p_ip}")
$evm.log(:info, "BHP: GetVM Info --> Status = #{p_status}")
#prov.set_option(:sysprep_spec_override, 'true')
#prov.set_option(:addr_mode, ["static", "Static"])
#prov.set_option(:param_ip, "#{p_ip}")
#prov.set_option(:parm_status, "#{p_status}")
#prov.set_option(:retires_on, Date.today)
#prov.set_option(:retired, true)
#prov.set_option(:retirement_state, "retired")
#prov.set_option(:retire_errors, "VM Retire Error")

$evm.log(:info, ": #{value}")
$evm.object['value']=value
