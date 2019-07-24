=begin
starttime	(O)
endtime		(O)
=end

payload = $evm.object['payload'].nil? ? {} : $evm.object['payload']
payload[:starttime] = $evm.object['starttime'] unless $evm.object['starttime'].nil? or $evm.object['starttime'].empty?
payload[:endtime] 	= $evm.object['endtime'] unless $evm.object['endtime'].nil? or $evm.object['endtime'].empty?

uri                     = "auditentires"
$evm.object['result']	= ""

client = $evm.instantiate("/Integration/RestClients/Turbonomic?method=#{$evm.object['method']}&uri=#{uri}&payload=#{payload.to_json}")
$evm.object['result'] = client['result']
