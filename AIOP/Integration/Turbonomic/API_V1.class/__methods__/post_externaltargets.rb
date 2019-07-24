=begin
type				(R)
targetIdentifier	(R)
=end

payload = {
  :type 			=> $evm.object['type'],
  :targetIdentifier => $evm.object['targetIdentifier']
}

uri                     = "externalTargets"
$evm.object['result']	= ""

client = $evm.instantiate("/Integration/RestClients/Turbonomic?method=#{$evm.object['method']}&uri=#{uri}&payload=#{payload.to_json}")
$evm.object['result'] = client['result']
