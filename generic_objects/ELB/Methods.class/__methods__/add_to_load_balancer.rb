
prov = $evm.root['miq_provision']
vm = prov.vm

lb_required = prov.get_option(:dialog_check_load_balancer)
 create_new_elb = prov.get_option(:dialog_new_elb_name)
 lb_type = prov.get_option(:dialog_load_balancer_type)

$evm.log(:info, "LB REQUIRED : #{lb_required}")
$evm.log(:info, "CREATE NEW ELB : #{create_new_elb}")
$evm.log(:info, "LB TYPE : #{lb_type}")

if lb_required
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
else
   $evm.log(:info, "Skipping Load Balancer")
end

