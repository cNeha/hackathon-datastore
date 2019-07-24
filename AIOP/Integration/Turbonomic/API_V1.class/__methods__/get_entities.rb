=begin
classname		(O)
entity			(O)
property		(O)
service			(O)
resource		(O)
=end

payload = $evm.object['payload'].nil? ? {} : $evm.object['payload']
payload[:classname] = $evm.object['classname'] unless $evm.object['classname'].nil? or $evm.object['classname'].empty?
payload[:entity] 	= $evm.object['entity'] unless $evm.object['entity'].nil? or $evm.object['entity'].empty?
payload[:property] 	= $evm.object['property'] unless $evm.object['property'].nil? or $evm.object['property'].empty?
payload[:service] 	= $evm.object['service'] unless $evm.object['service'].nil? or $evm.object['service'].empty?
payload[:resource] 	= $evm.object['resource'] unless $evm.object['resource'].nil? or $evm.object['resource'].empty?

uri                     = "markets/#{$evm.object['uuid']}/entities"
$evm.object['result']	= ""

client = $evm.instantiate("/Integration/RestClients/Turbonomic?method=#{$evm.object['method']}&uri=#{uri}&payload=#{payload.to_json}")
$evm.object['result'] = client['result']
