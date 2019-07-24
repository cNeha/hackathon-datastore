$evm.log("info", "Value of #{$evm.root['dialog_check_list']}")
if $evm.root['dialog_check_list'] == 't'
  $evm.object['visible'] = true
else
  $evm.object['visible'] = false
end
