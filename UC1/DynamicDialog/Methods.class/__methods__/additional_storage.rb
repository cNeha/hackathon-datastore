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
  value[0]="1"
  value[1]="2"
  value[2]="3"
  value[3]="4"
  $evm.object["values"] = {1 => "1", 2 => "2", 3 => "3", 4 => "4"}

end
