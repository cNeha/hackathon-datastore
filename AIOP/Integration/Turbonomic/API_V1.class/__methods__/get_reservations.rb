=begin
state	(O)
=end

payload = $evm.object['payload'].nil? ? {} : $evm.object['payload']
payload[:state] = $evm.object['state'] unless $evm.object['state'].nil? or $evm.object['state'].empty?

uri                     = "reservations"
$evm.object['result']	= ""

unless $evm.object['uuid'].nil?
	uri << "/#{$evm.object['uuid']}"  
end

client = $evm.instantiate("/Integration/RestClients/Turbonomic?method=#{$evm.object['method']}&uri=#{uri}&payload=#{payload.to_json}")
$evm.object['result'] = client['result']
