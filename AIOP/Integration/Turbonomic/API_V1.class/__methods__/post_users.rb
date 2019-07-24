=begin
UserName (R)
UserPassword (R)
UserRole (R)
LoginProvider (O)
UserType (O)
UserScope[] (O)
=end

payload = {
  :UserName 	=> $evm.object['UserName'],
  :UserPassword => $evm.object['UserPassword'],
  :UserRole 	=> $evm.object['UserRole']
}
payload[:LoginProvider] = $evm.object['LoginProvider'] unless $evm.object['LoginProvider'].nil? or $evm.object['LoginProvider'].empty?
payload[:UserType] 		= $evm.object['UserType'] unless $evm.object['UserType'].nil? or $evm.object['UserType'].empty?
payload[:UserScope[]] 	= $evm.object['UserScope'] unless $evm.object['UserScope'].nil? or $evm.object['UserScope'].empty?

uri                     = "users"
$evm.object['result']	= ""

client = $evm.instantiate("/Integration/RestClients/Turbonomic?method=#{$evm.object['method']}&uri=#{uri}&payload=#{payload.to_json}")
$evm.object['result'] = client['result']
