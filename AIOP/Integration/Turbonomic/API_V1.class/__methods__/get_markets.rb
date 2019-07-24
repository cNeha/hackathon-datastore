payload = $evm.object['payload'].nil? ? {} : $evm.object['payload']

uri                     = "markets"
$evm.object['result']	= ""

unless $evm.object['uuid'].nil?
  uri << "/#{$evm.object['uuid']}"
end

client = $evm.instantiate("/Integration/RestClients/Turbonomic?method=#{$evm.object['method']}&uri=#{uri}&payload=#{payload.to_json}")
$evm.object['result'] = client['result']
