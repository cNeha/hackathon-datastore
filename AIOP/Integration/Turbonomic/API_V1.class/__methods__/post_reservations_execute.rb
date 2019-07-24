=begin
action		(R)
=end

payload = {
  :action => $evm.object['action']
}

uri                     = "reservations/#{$evm.object['uuid']}"
$evm.object['result']	= ""

client = $evm.instantiate("/Integration/RestClients/Turbonomic?method=#{$evm.object['method']}&uri=#{uri}&payload=#{payload.to_json}")
$evm.object['result'] = client['result']
