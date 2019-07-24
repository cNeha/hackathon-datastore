=begin
complete	(O)
=end

payload = $evm.object['payload'].nil? ? {} : $evm.object['payload']
payload[:complete] = $evm.object['complete'] unless $evm.object['complete'].nil? or $evm.object['complete'].empty?

uri                     = "markets/#{$evm.object['uuid']}/#{$evm.object['type']}/#{$evm.object['entity_uuid']}/actionitems"
$evm.object['result']	= ""

client = $evm.instantiate("/Integration/RestClients/Turbonomic?method=#{$evm.object['method']}&uri=#{uri}&payload=#{payload.to_json}")
$evm.object['result'] = client['result']
