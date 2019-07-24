payload = $evm.object['payload'].nil? ? {} : $evm.object['payload']

uri                     = "roles"
$evm.object['result']	= ""

unless $evm.object['role_uuid'].nil?
  uri << "/#{$evm.object['role_uuid']}"
end

client = $evm.instantiate("/Integration/RestClients/Turbonomic?method=#{$evm.object['method']}&uri=#{uri}&payload=#{payload.to_json}")
$evm.object['result'] = client['result']
