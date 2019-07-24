payload = $evm.object['payload'].nil? ? {} : $evm.object['payload']

uri                     = "markets/#{$evm.object['marketname']}/#{$evm.object['entity_type_1']}/#{$evm.object['entity_name_1']}/#{$evm.object['service']}/#{$evm.object['entity_type_2']}/#{$evm.object['entity_name_2']}"
$evm.object['result']	= ""

client = $evm.instantiate("/Integration/RestClients/Turbonomic?method=#{$evm.object['method']}&uri=#{uri}&payload=#{payload.to_json}")
$evm.object['result'] = client['result']
