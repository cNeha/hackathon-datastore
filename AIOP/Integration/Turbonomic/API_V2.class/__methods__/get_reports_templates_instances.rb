require 'json'

payload = $evm.object['payload'].nil? ? {} : JSON.parse($evm.object['payload']) rescue {}

uri                     = "reports/templates/#{$evm.object['uuid']}/instances"
unless $evm.object['instance_uuid'].nil?
  uri << "/#{$evm.object['instance_uuid']}"
end
$evm.object['result']	= ""

client = $evm.instantiate("/Integration/RestClients/Turbonomic?method=#{$evm.object['method']}&uri=#{uri}&payload=#{payload.to_json}")
$evm.object['result'] = client['result']

exit MIQ_OK
