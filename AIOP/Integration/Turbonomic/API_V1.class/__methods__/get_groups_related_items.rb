payload = $evm.object['payload'].nil? ? {} : $evm.object['payload']

uri                     = "markets/Market/group/#{$evm.object['group_uuid']}/#{$evm.object['related_item']}"
$evm.object['result']	= ""

client = $evm.instantiate("/Integration/RestClients/Turbonomic?method=#{$evm.object['method']}&uri=#{uri}&payload=#{payload.to_json}")
$evm.object['result'] = client['result']
