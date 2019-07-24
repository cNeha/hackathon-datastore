=begin
property	(O)
service		(O)
resource	(O)
starttime	(O)
endtime		(O)
=end

payload = $evm.object['payload'].nil? ? {} : $evm.object['payload']
payload[:property] 	= $evm.object['property'] unless $evm.object['property'].nil? or $evm.object['property'].empty?
payload[:service] 	= $evm.object['service'] unless $evm.object['service'].nil? or $evm.object['service'].empty?
payload[:resource] 	= $evm.object['resource'] unless $evm.object['resource'].nil? or $evm.object['resource'].empty?
payload[:starttime] = $evm.object['starttime'] unless $evm.object['starttime'].nil? or $evm.object['starttime'].empty?
payload[:endtime] 	= $evm.object['endtime'] unless $evm.object['endtime'].nil? or $evm.object['endtime'].empty?

uri                     = "markets/#{$evm.object['uuid']}/#{$evm.object['type1']}/#{$evm.object['entity_uuid']}/#{$evm.object['type2']}"
$evm.object['result']	= ""

client = $evm.instantiate("/Integration/RestClients/Turbonomic?method=#{$evm.object['method']}&uri=#{uri}&payload=#{payload.to_json}")
$evm.object['result'] = client['result']
