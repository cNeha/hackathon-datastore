payload = $evm.object['payload'].nil? ? {} : $evm.object['payload']

group_uuid				= $evm.object['group_uuid'].nil? ? 'GROUP-VMTSegment' : $evm.object['group_uuid']
uri                     = "groups/#{group_uuid}/entities"
$evm.object['result']	= ""

client = $evm.instantiate("/Integration/RestClients/Turbonomic?method=#{$evm.object['method']}&uri=#{uri}&payload=#{payload.to_json}")
$evm.object['result'] = client['result']
