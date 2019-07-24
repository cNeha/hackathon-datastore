#
# Description: Method to get templates
#
os_type = $evm.root['dialog_param_ostype_list']
list_values = {
  'required'   => false,
  'protected'  => false,
  'read_only'  => false
}
values = {}
if os_type != ""
  $evm.object['visible'] = true
end

list_values.each do |key, value|
  $evm.object[key] = value
end
template = "windows"
$evm.vmdb('ManageIQ_Providers_Vmware_InfraManager_Template').all.each { |x| if x.platform == template then values[x.name] = x.name end}
$evm.object['values']=values
