#
# Description: <Method description here>
#
#
# Description: Add extra disks
#
prov = $evm.root['miq_provision']
vm = prov.vm
$evm.log('info', "BHP: Adding extra disks if requested")
size_of_disks = prov.miq_request.options[:dialog]['dialog_option_0_size_of_disks']
if vm.storage.present?
  $evm.log('info', "BHP: SIZES: #{size_of_disks}; VM NAME: #{vm.name}; STORAGE NAME: #{vm.storage.name}")
else
  $evm.log('info', "BHP: VM storage not defined")  
  # for the time being, exit without error
  exit MIQ_OK
end
if size_of_disks.present?
  size_of_disks.split(",").each do |size|
    real_size = size.to_i * 1024
    $evm.log('info', "BHP: Adding #{real_size} GB drive to #{vm.name} at #{vm.storage.name}")
    sleep 5
    vm.add_disk("[#{vm.storage.name}]", real_size)
  end
else
  $evm.log('info', "BHP: No extra disks requested")
end
