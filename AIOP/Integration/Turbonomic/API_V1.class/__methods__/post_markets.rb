=begin
state			(R)
constraint		(R)
templateName	(O)
count			(O)
scope			(O)
=end

payload = {
  :state 		=> $evm.object['state'],
  :constraint 	=> $evm.object['constraint']
}
payload[:templateName] 	= $evm.object['templateName'] unless $evm.object['templateName'].nil? or $evm.object['templateName'].empty?
payload[:count] 		= $evm.object['count'] unless $evm.object['count'].nil? or $evm.object['count'].empty?
payload[:scope] 		= $evm.object['scope'] unless $evm.object['scope'].nil? or $evm.object['scope'].empty?

uri                     = "markets/#{$evm.object['uuid']}"
$evm.object['result']	= ""

client = $evm.instantiate("/Integration/RestClients/Turbonomic?method=#{$evm.object['method']}&uri=#{uri}&payload=#{payload.to_json}")
$evm.object['result'] = client['result']
