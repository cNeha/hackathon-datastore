lb = $evm.vmdb('load_balancer').first
$evm.log(:info, "Below VMs are part of load balancer #{lb.name}")
lb.vms.each do |v|
  $evm.log(:info, "#{v.name}")
end
#$evm.log(:info, "Instances under load balancer #{lb} are #{lb.vms}")
