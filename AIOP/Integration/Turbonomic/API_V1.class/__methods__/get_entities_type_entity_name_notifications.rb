=begin
category	(O)
active		(R)
=end

payload = {
  :active => $evm.object['active']
}
payload[:category] = $evm.object['category'] unless $evm.object['category'].nil? or $evm.object['category'].empty?

uri                     = "markets/#{$evm.object['uuid']}/#{$evm.object['type']}/#{$evm.object['entity_uuid']}/notifications"
$evm.object['result']	= ""

client = $evm.instantiate("/Integration/RestClients/Turbonomic?method=#{$evm.object['method']}&uri=#{uri}&payload=#{payload.to_json}")
$evm.object['result'] = client['result']
