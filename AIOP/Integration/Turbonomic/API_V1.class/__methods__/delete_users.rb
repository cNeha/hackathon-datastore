payload = $evm.object['payload'].nil? ? {} : $evm.object['payload']

uri                     = "users/#{$evm.object['user_uuid']}"
$evm.object['result']	= ""

client = $evm.instantiate("/Integration/RestClients/Turbonomic?method=#{$evm.object['method']}&uri=#{uri}&payload=#{payload.to_json}")
$evm.object['result'] = client['result']
