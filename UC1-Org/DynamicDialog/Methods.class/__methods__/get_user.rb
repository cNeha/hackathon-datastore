#
# Description: <Method description here>
#
user = $evm.root['user'] 
$evm.object['required'] = true 
$evm.object['protected'] = false 
$evm.object['read_only'] = true 
$evm.object['value'] = user.name
