=begin
action		(R)
=end

payload = $evm.object['payload'].nil? ? {} : $evm.object['payload']
payload['action'] = $evm.object['action']

uri                     = "actionlogs/#{$evm.object['uuid']}/actionitems/#{$evm.object['item_uuid']}"
$evm.object['result']	= ""

client = $evm.instantiate("/Integration/RestClients/Turbonomic?method=#{$evm.object['method']}&uri=#{uri}&payload=#{payload.to_json}")
$evm.object['result'] = client['result']
