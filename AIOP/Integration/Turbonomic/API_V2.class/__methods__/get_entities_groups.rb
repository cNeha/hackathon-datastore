require 'json'

payload = $evm.object['payload'].nil? ? {} : JSON.parse($evm.object['payload']) rescue {}

uri                     = "entities/#{$evm.object['uuid']}/groups"
$evm.object['result']	= ""

client = $evm.instantiate("/Integration/RestClients/Turbonomic?method=#{$evm.object['method']}&uri=#{uri}&payload=#{payload.to_json}")
$evm.object['result'] = client['result']

exit MIQ_OK
