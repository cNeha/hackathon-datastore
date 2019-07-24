=begin
targetType		(R)
nameOrAddress	(R)
username		(R)
password		(R)
username2		(O)
password2		(O)
domainName		(O)
port			(O)
scopeName		(O)
id				(O)
=end

payload = {
 :state 		=> $evm.object['state'],
 :constraint 	=> $evm.object['constraint'], 
 :template 		=> $evm.object['template'], 
 :count 		=> $evm.object['count'], 
 :scope 		=> $evm.object['scope']
}
payload[:username2] 	= $evm.object['username2'] unless $evm.object['username2'].nil? or $evm.object['username2'].empty?
payload[:password2] 	= $evm.object['password2'] unless $evm.object['password2'].nil? or $evm.object['password2'].empty?
payload[:domainName] 	= $evm.object['domainName'] unless $evm.object['domainName'].nil? or $evm.object['domainName'].empty?
payload[:port] 			= $evm.object['port'] unless $evm.object['port'].nil? or $evm.object['port'].empty?
payload[:scopeName] 	= $evm.object['scopeName'] unless $evm.object['scopeName'].nil? or $evm.object['scopeName'].empty?
payload[:id] 			= $evm.object['id'] unless $evm.object['id'].nil? or $evm.object['id'].empty?

uri                     = "targets"
$evm.object['result']	= ""

unless $evm.object['uuid'].nil?
  uri << "/#{$evm.object['uuid']}"
end

client = $evm.instantiate("/Integration/RestClients/Turbonomic?method=#{$evm.object['method']}&uri=#{uri}&payload=#{payload.to_json}")
$evm.object['result'] = client['result']
