#
# Description: <Method description here>
#

subnet_mask = ""
cidr = $evm.root['dialog_param_cidr']
$evm.log(:info, "CIDR is #{cidr}")

cidr_suffix = cidr.split("/")[1].to_i

case cidr_suffix
  when 24
    subnet_mask = "255.255.255.0"
  when 16
    subnet_mask = "255.255.0.0"
  when 8
    subnet_mask = "255.0.0.0"
  else
    $evm.log("info", "Invalid CIDR")
end
$evm.log(:info, "SUBNET MASK IS #{subnet_mask}")
$evm.object['value'] = subnet_mask
  


