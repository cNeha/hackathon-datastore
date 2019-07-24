#
# Description: <Method description here>
#
app_type = $evm.root['dialog_radio_button_app_type']
$evm.log(:info, "BHP: App Type : #{app_type}")
$evm.object['required'] = false 
$evm.object['protected'] = false 
$evm.object['read_only'] = false
value=""
if app_type != "<Choose>" and app_type != "New"
  $evm.object['visible'] = false
else
  $evm.object['visible'] = true
end
