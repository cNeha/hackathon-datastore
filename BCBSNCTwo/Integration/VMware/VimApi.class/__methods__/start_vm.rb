#
# Description: <Method description here>
#
#
# Description: <Method description here>
#
case $evm.root['vmdb_object_type']
when 'miq_provision'
  prov = $evm.root['miq_provision']  
  ws_values = prov.options.fetch(:ws_values, {})

  if ws_values.has_key?(:disk_size_gb) 
    size = ws_values[:disk_size_gb].to_i
  else
    size = 10
    ws_values[:disk_size_gb] = 10
    prov.set_option(:ws_values, ws_values)
  end   
   
  new_disks = []
  scsi_start_idx = 1

  new_disks << {:bus => 0, :pos => scsi_start_idx, :sizeInMB => size.gigabytes / 1.megabyte, :backing => {:thinprovisioned => true}}
  prov.set_option(:disk_scsi, new_disks) unless new_disks.blank?
  $evm.log(:info, "Provisioning object <:disk_scsi> updated with <#{prov.get_option(:disk_scsi)}>")
when 'vm'
  vm = $evm.root['vm']
  size = $evm.root['dialog_disk_size_gb'].to_i
  
  $evm.log(:info, "AddDisk: Creating a new #{size}GB disk on Storage: #{vm.storage_name}")
  # Get the vimVm object
  vim_vm = vm.object_send('instance_eval', 'with_provider_object { | vimVm | return vimVm }')
  vim_vm.addDisk("[#{vm.storage_name}]", size * 1024, 'label', 'summary', {dependent: true, thin_provisioned: true})
end
$evm.log(:info, "Processing add_disk...Complete")
