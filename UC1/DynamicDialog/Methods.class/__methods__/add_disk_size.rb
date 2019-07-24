#
# Description: <Method description here>
#
add_storage = $evm.root['dialog_param_additional_storage']

$evm.object['required'] = false
$evm.object['protected'] = false 
$evm.object['read_only'] = false
value=""
if add_storage != "Yes"
  $evm.object['visible'] = false
else
  $evm.object['visible'] = true
end

