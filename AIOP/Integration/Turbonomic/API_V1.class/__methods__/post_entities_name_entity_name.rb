=begin
count			(R)
budget			(R)
constraint		(O)
templateName	(O)
=end

payload = {
  :count 	=> $evm.object['count'],
  :budget 	=>	$evm.object['budget']
}
payload[:constraint] 	= $evm.object['constraint'] unless $evm.object['constraint'].nil? or $evm.object['constraint'].empty?
payload[:templateName] 	= $evm.object['templateName'] unless $evm.object['templateName'].nil? or $evm.object['templateName'].empty?

uri                     = "markets/#{$evm.object['marketname']}/entities/#{$evm.object['entity_uuid']}"
$evm.object['result']	= ""

client = $evm.instantiate("/Integration/RestClients/Turbonomic?method=#{$evm.object['method']}&uri=#{uri}&payload=#{payload.to_json}")
$evm.object['result'] = client['result']
