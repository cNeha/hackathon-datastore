=begin
category	(O)
active		(O)
starttime	(O)
endtime		(O)
=end

payload = {}
payload[:category] 	= $evm.object['category'] unless $evm.object['category'].nil? or $evm.object['category'].empty?
payload[:active] 	= $evm.object['active'] unless $evm.object['active'].nil? or $evm.object['active'].empty?
payload[:starttime] = $evm.object['starttime'] unless $evm.object['starttime'].nil? or $evm.object['starttime'].empty?
payload[:endtime] 	= $evm.object['endtime'] unless $evm.object['endtime'].nil? or $evm.object['endtime'].empty?

uri                     = "notifications"
$evm.object['result']	= ""

client = $evm.instantiate("/Integration/RestClients/Turbonomic?method=#{$evm.object['method']}&uri=#{uri}&payload=#{payload.to_json}")
$evm.object['result'] = client['result']
