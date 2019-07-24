require 'json'

payload = $evm.object['payload'].nil? ? {} : JSON.parse($evm.object['payload']) rescue {}

uri                     = "groups/#{$evm.object['uuid']}/settings"
unless $evm.object['manager_uuid'].nil?
  uri << "/#{$evm.object['manager_uuid']}"
end
unless $evm.object['setting_uuid'].nil?
  uri << "/#{$evm.object['setting_uuid']}"
end
$evm.object['result']	= ""

client = $evm.instantiate("/Integration/RestClients/Turbonomic?method=#{$evm.object['method']}&uri=#{uri}&payload=#{payload.to_json}")
$evm.object['result'] = client['result']

exit MIQ_OK
