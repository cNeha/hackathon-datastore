payload = $evm.object['payload'].nil? ? {} : $evm.object['payload']

uri                     = "usergroups"
$evm.object['result']	= ""

unless $evm.object['group_uuid'].nil?
  uri << "/#{$evm.object['group_uuid']}"
end

client = $evm.instantiate("/Integration/RestClients/Turbonomic?method=#{$evm.object['method']}&uri=#{uri}&payload=#{payload.to_json}")
$evm.object['result'] = client['result']
