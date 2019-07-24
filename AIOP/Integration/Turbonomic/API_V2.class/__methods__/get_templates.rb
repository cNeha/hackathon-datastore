require 'json'

payload = $evm.object['payload'].nil? ? {} : JSON.parse($evm.object['payload']) rescue {}

uri                     = "templates"
unless $evm.object['uuid_or_type'].nil?
  uri << "/#{$evm.object['uuid_or_type']}"
end
unless $evm.object['action'].nil?
  uri << "?action=#{$evm.object['action']}"
end
$evm.object['result']	= ""

client = $evm.instantiate("/Integration/RestClients/Turbonomic?method=#{$evm.object['method']}&uri=#{uri}&payload=#{payload.to_json}")
$evm.object['result'] = client['result']

exit MIQ_OK
