go_class = $evm.vmdb('generic_object_definition').first
$evm.log(:info, "Go Class is #{go_class}")
go_object = go_class.create_object(:name => "lb1", :lb_name => "elb", :lb_type => "round-robin")
$evm.log(:info, "GO OBJECT is #{go_object}")
service = $evm.vmdb('service').first
$evm.log(:info, "-----------------ASSOCIATIONS..........................")
go_object.lb_vms += [service]
go_object.save!
go_object.add_to_service(service)
aws = $evm.vmdb('ems').find_by_name('aws')
vm =  aws.vms.first
$evm.log(:info, "VM is #{vm}")
go_object.lb_vm += [vm]
go_object.save!

$evm.log(:info, "#{ go_object.lb_vms}")

$evm.log(:info, "---------------------------------------")
$evm.log(:info, "#{ go_object.lb_vm}")

$evm.log(:info, " Execute List Instances via Generic Object")
go_object.list_instances
