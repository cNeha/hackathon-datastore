prov = $evm.root['miq_provision']
ip = prov.get_option(:dialog_ipaddr)
$evm.log(:info, "IP address is #{ip}")
###############################
#Setting new IP Address
##############################
addr_mode = prov.set_option('addr_mode', 'static')
subnet_mask = prov.set_option('subnet_mask', '255.255.255.0')
res = prov.set_option('ip_addr', ip)
$evm.log("info", "Result is #{res}")

