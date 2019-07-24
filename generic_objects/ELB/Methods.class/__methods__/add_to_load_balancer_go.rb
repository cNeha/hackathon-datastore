
prov = $evm.root['miq_provision']
vm = prov.vm
$evm.log(:info, "PROV ID IS #{prov.id}")
lb_required = prov.get_option(:dialog_check_load_balancer)
create_new_elb = prov.get_option(:dialog_new_elb_name)
lb_type = prov.get_option(:dialog_load_balancer_type)

$evm.log(:info, "LB REQUIRED : #{lb_required}")
$evm.log(:info, "CREATE NEW ELB : #{create_new_elb}")
$evm.log(:info, "LB TYPE : #{lb_type}")

go_class = $evm.vmdb('generic_object_definition').where(:name => 'LoadBalancer').first
go_object = go_class.create_object(:name => create_new_elb, :lb_name => create_new_elb, :lb_type => lb_type, :miq_provision_request_id => prov.miq_request.id, :miq_provision_task_id => prov.id)

$evm.log(:info, "-----------------ASSOCIATIONS..........................")
go_object.lb_vm += [vm]
go_object.save!
$evm.log(:info, "#{ go_object.lb_vm}")

$evm.log(:info, "Add to load balancer")
go_object.add_to_lb if lb_required


  
     

