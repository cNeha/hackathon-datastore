payload = $evm.object['payload'].nil? ? {} : $evm.object['payload']

uri                     = "markets/#{$evm.object['marketname']}/hosts/#{$evm.object['entity_uuid']}/state/#{$evm.object['state_val']}"
$evm.object['result']	= ""

client = $evm.instantiate("/Integration/RestClients/Turbonomic?method=#{$evm.object['method']}&uri=#{uri}&payload=#{payload.to_json}")
$evm.object['result'] = client['result']
