=begin
groupname (R)
seType (R)
reportEnabled (R)
uuidList[] (O)
xmlId (O)
expVal (O)
=end

payload = {
  :groupname 		=> $evm.object['groupname'],
  :seType 			=> $evm.object['seType'],
  :reportEnabled 	=> $evm.object['reportEnabled']
}
payload[:uuidList] 	= $evm.object['uuidList'] unless $evm.object['uuidList'].nil? or $evm.object['uuidList'].empty?
payload[:xmlId] 	= $evm.object['xmlId'] unless $evm.object['xmlId'].nil? or $evm.object['xmlId'].empty?
payload[:expVal] 	= $evm.object['expVal'] unless $evm.object['expVal'].nil? or $evm.object['expVal'].empty?

uri                     = "groups"
$evm.object['result']	= ""

client = $evm.instantiate("/Integration/RestClients/Turbonomic?method=#{$evm.object['method']}&uri=#{uri}&payload=#{payload.to_json}")
$evm.object['result'] = client['result']
