payload = $evm.object['payload'].nil? ? {} : $evm.object['payload']

uri                     = "groups/storagecontrollers/#{$evm.object['group_uuid']}/resources/Actionpermit/capacity/#{$evm.object['value']}"
$evm.object['result']	= ""

client = $evm.instantiate("/Integration/RestClients/Turbonomic?method=#{$evm.object['method']}&uri=#{uri}&payload=#{payload.to_json}")
$evm.object['result'] = client['result']
