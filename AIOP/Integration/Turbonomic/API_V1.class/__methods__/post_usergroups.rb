=begin
GroupName (R)
GroupRole (R)
GroupType (R) [DedicatedCustomer, SharedCustomer (Default)]
GroupScope[] (O)
=end

if $evm.object['GroupType'].nil?
  $evm.object['GroupType'] = "SharedCustomer"
end

payload = {
  :GroupName => $evm.object['GroupName'],
  :GroupRole => $evm.object['GroupRole'],
  :GroupType => $evm.object['GroupType']
}
payload[:GroupScope[]] = $evm.object['GroupScope'] unless $evm.object['GroupScope'].nil? or $evm.object['GroupScope'].empty?

uri                     = "usergroups"
$evm.object['result']	= ""

client = $evm.instantiate("/Integration/RestClients/Turbonomic?method=#{$evm.object['method']}&uri=#{uri}&payload=#{payload.to_json}")
$evm.object['result'] = client['result']
