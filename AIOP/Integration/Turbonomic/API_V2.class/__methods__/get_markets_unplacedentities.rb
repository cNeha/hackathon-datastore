require 'json'

payload = $evm.object['payload'].nil? ? {} : JSON.parse($evm.object['payload']) rescue {}

uri                     = "markets/#{$evm.object['uuid']}/unplacedentities"
$evm.object['result']	= ""

client = $evm.instantiate("/Integration/RestClients/Turbonomic?method=#{$evm.object['method']}&uri=#{uri}&payload=#{payload.to_json}")
$evm.object['result'] = client['result']

exit MIQ_OK
