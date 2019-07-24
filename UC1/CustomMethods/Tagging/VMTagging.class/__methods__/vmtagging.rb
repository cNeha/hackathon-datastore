#
# Tag the VM with power off after hours if it's a cloud one. Save some money.
#
# To get the VM handle, we need to figure out how we've been called
case $evm.root['vmdb_object_type']
  when 'miq_provision'                # called from a VM provision workflow
    prov = $evm.root['miq_provision']
    vm = prov.vm
    protection = prov.options[:retirement_protect]
    maintain = prov.options[:vm_maintain]
    allow_ssa = prov.options[:allow_ssa]
  when 'vm'
    vm = $evm.root['vm']              # called from a button
    protection = "t"
    maintain = "t"
    allow_ssa = "t"
  when 'automation_task'              # called from a RESTful automation request, vm_id is a passed parameter
    attrs = $evm.root['automation_task'].options[:attrs]
    vm_id = attrs[:vm_id]
    vm = $evm.vmdb('vm').find_by_id(vm_id)
    protection = "t"
    maintain = "t"
    allow_ssa = "t"
end
#$evm.instantiate('/Discovery/ObjectWalker/object_walker')
# Tag for VM delete protection
if protection == "t"
  vm.tag_assign("vm_protect/retirement_protect")
  $evm.log('info', "BHP: VM NAME: #{vm.name} protected from retirement")
else
  vm.tag_assign("lifecycle/retire_full")
  $evm.log('info', "BHP: VM NAME: #{vm.name} setting full retirement when retired")
end

if maintain == "t"
  vm.tag_assign("vm_protect/vm_maintain")
  $evm.log('info', "BHP: VM NAME: #{vm.name} protected from de-provisioning on error")
end

if allow_ssa == "f"
  vm.tag_assign("smartstate/do_not_analyse")
  $evm.log('info', "BHP: VM NAME: #{vm.name} protected from SmartState scanning")
end

# Tag for cloud operations
case vm.vendor
  when 'amazon'
    if ! $evm.execute('category_exists?', "aws_region")
      $evm.log(:info, "BHP: Creating Amazon Region tag category")
      $evm.execute('category_create', :name => "aws_region", :single_value => false, :description=> "Amazon Regions")
    end
    # Check to see if the CF tag exists for the AWS region and create it if not
  	region = vm.location.split(".")[1].gsub("-","_")
	if ! $evm.execute('tag_exists?', "aws_region", region)
      $evm.log(:info, "BHP: Creating Amazon Region tag, #{region}")
      $evm.execute('tag_create', "aws_region", :name => region, :description => region)
	end
    vm.tag_assign("aws_region/" + region)
    vm.tag_assign("after_hours_operation/off")
    $evm.log('info', "BHP: #{vm.name} is a public cloud instance in region #{region}, turn off after hours")
  when 'azure'
    vm.tag_assign("after_hours_operation/off")
    $evm.log('info', "BHP: #{vm.name} is a public cloud instance, turn off after hours")
  when 'google'
    vm.tag_assign("after_hours_operation/off")
    $evm.log('info', "BHP: #{vm.name} is a public cloud instance, turn off after hours")
  else
    $evm.log('info', "BHP: #{vm.name} is not a public cloud instance, leave it alone")
end
