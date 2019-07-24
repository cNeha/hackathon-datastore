#
# Description: Method Check OS Type
#
os_type = $evm.root['dialog_param_ostype_list']
list_values = {
  'required'   => false,
  'protected'  => false,
  'read_only'  => true
}
value=""
if os_type != ""
  $evm.object['visible'] = true
else
  $evm.object['visible'] = false
end
value = os_type
list_values.each do |key, value|
  $evm.object[key] = value
end
$evm.object['value']=value
