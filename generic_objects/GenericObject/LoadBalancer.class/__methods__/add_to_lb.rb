# This method will check the options selected by an end user and accordingly add it to the load balancer as selected by user.


create_new_elb = $evm.root['generic_object'].attributes['properties']['lb_name']
lb_type = $evm.root['generic_object'].attributes['properties']['lb_type']
miq_provision_request_id = $evm.root['generic_object'].attributes['properties']['miq_provision_request_id']
miq_provision_id = $evm.root['generic_object'].attributes['properties']['miq_provision_task_id']
prov = $evm.vmdb(:miq_provision).find_by_id(miq_provision_id)
$evm.log(:info, "Prov IS #{prov}")
$evm.root['elb_name'] = prov.get_option(:dialog_new_elb_name)
$evm.log(:info, "ELB NAME is #{$evm.root['elb_name']}")
$evm.root['availability_zone'] = prov.get_option(:dialog_param_az)
$evm.log(:info, "Availability zone is #{$evm.root['availability_zone']}")
$evm.root['elb_port'] = prov.get_option(:dialog_elb_port)
$evm.log(:info, "ELB PORT is #{$evm.root['elb_port']}")
$evm.root['instance_id'] = prov.destination.ems_ref
$evm.log(:info, "INSTANCE ID is #{$evm.root['instance_id']}")
$evm.root['region'] = prov.get_option(:dialog_param_region)
$evm.log(:info, "REGION is #{$evm.root['region']}")
$evm.root['subnet_id'] = prov.destination.cloud_subnet.ems_ref
$evm.log(:info, "SUBNET ID is #{$evm.root['subnet_id']}")


$evm.log(:info, "CREATE NEW ELB is #{create_new_elb}")
$evm.log(:info, "LB TYPE is #{lb_type}")

    if lb_type == '1'
      unless create_new_elb.nil?
          $evm.instantiate("/ELB/Methods/AddToNewLB")
      else
          $evm.instantiate("/ELB/Methods/AddToExistingLB")
      end
    elsif lb_type == '2'
       $evm.instantiate("/F5/Methods/AddToF5LB")
    else
       $evm.log(:info,"Invalid LB type")
    end


