payload = $evm.object['payload'].nil? ? {} : $evm.object['payload']

uri                     = "markets/Market/storagecontrollers/#{$evm.object['storage_name']}/resources/ActionPermit/capacity/#{$evm.object['value']}"
$evm.object['result']	= ""

client = $evm.instantiate("/Integration/RestClients/Turbonomic?method=#{$evm.object['method']}&uri=#{uri}&payload=#{payload.to_json}")
$evm.object['result'] = client['result']
