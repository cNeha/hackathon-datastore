=begin
profileUuid			(O)
name				(R)
scope				(O)
uri					(O)
relatedTemplates[]	(R)
=end

payload = {
  :name 				=> $evm.object['name'],
  :relatedTemplates[] 	=> $evm.object['relatedTemplates']
}
payload[:profileUuid] 	= $evm.object['profileUuid'] unless $evm.object['profileUuid'].nil? or $evm.object['profileUuid'].empty?
payload[:scope] 		= $evm.object['scope'] unless $evm.object['scope'].nil? or $evm.object['scope'].empty?
payload[:uri] 			= $evm.object['uri'] unless $evm.object['uri'].nil? or $evm.object['uri'].empty?

uri                     = "deploymentprofiles"
$evm.object['result']	= ""

unless $evm.object['uuid'].nil?
	uri << "/#{$evm.object['uuid']}"  
end

client = $evm.instantiate("/Integration/RestClients/Turbonomic?method=#{$evm.object['method']}&uri=#{uri}&payload=#{payload.to_json}")
$evm.object['result'] = client['result']
