payload = $evm.object['payload'].nil? ? {} : $evm.object['payload']

uri                     = "groups/#{$evm.object['group_uuid']}/applications/#{$evm.object['app_name']}"
$evm.object['result']	= ""

client = $evm.instantiate("/Integration/RestClients/Turbonomic?method=#{$evm.object['method']}&uri=#{uri}&payload=#{payload.to_json}")
$evm.object['result'] = client['result']
