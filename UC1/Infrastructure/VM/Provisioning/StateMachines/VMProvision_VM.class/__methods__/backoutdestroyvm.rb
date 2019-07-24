# If there has been a failure post provision that we can't recover from we execute this that deletes the VM
#
$evm.log(:info, "BHP: There has been a failure post provision, proceeding to delete the VM")
prov = $evm.root['miq_provision']
vm = prov.vm
# Clean up
$evm.log(:info, "Proceed to Power off the VM")
vm.stop
sleep(20)
vm.refresh
if vm.power_state != "off"
  vm.refresh
  $evm.root['ae_result'] = 'retry'
  $evm.root['ae_retry_interval'] = 1.minute
else
  $evm.root['ae_result'] = 'ok'
end
$evm.log(:info, "VM is off, proceed to delete")
vm.remove_from_disk
sleep(60)
vm.refresh

