vm = $evm.root['vm']
provider = vm.ext_management_system
$evm.log(:info, "Detected Provider: #{provider.name}")
