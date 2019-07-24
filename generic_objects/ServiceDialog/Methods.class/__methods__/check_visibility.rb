$evm.log("info", "Value of #{$evm.root['dialog_check_load_balancer']}")
if $evm.root['dialog_check_load_balancer'] == 't'
  $evm.object['visible'] = true
  $evm.object["values"] = [[1, "ELB"], [2, "F5"]]
else
  $evm.object['visible'] = false
end

