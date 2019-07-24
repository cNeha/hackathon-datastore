payload = $evm.object['payload'].nil? ? {} : $evm.object['payload']

uri                     = "markets/Market/virtualmachines/#{$evm.object['vm_uuid']}/applications/#{$evm.object['app_name']}/resources/ActionPermit/used/#{$evm.object['value']}"
$evm.object['result']	= ""

client = $evm.instantiate("/Integration/RestClients/Turbonomic?method=#{$evm.object['method']}&uri=#{uri}&payload=#{payload.to_json}")
$evm.object['result'] = client['result']
