payload = $evm.object['payload'].nil? ? {} : $evm.object['payload']

uri                     = "markets/#{$evm.object['marketname']}/applications/#{$evm.object['app_name']}/services/#{$evm.object['service_name']}/#{$evm.object['attribute']}/#{$evm.object['value']}"
$evm.object['result']	= ""

client = $evm.instantiate("/Integration/RestClients/Turbonomic?method=#{$evm.object['method']}&uri=#{uri}&payload=#{payload.to_json}")
$evm.object['result'] = client['result']
