=begin
name		(R)
startDate	(R)
endDate		(R)
startTime	(R)
endTime		(R)
color		(O)
group		(O)
action		(R)
actionMode	(R)
recur		(O)
note		(O)
=end

payload = {
  :name	 		=> $evm.object['name'],
  :startDate 	=> $evm.object['startDate'],
  :endDate 		=> $evm.object['endDate'],
  :startTime 	=> $evm.object['startTime'],
  :endTime 		=> $evm.object['endTime'],
  :action 		=> $evm.object['action'],
  :actionMode 	=> $evm.object['actionMode']
}
payload[:color] = $evm.object['color'] unless $evm.object['color'].nil? or $evm.object['color'].empty?
payload[:group] = $evm.object['group'] unless $evm.object['group'].nil? or $evm.object['group'].empty?
payload[:recur] = $evm.object['recur'] unless $evm.object['recur'].nil? or $evm.object['recur'].empty?
payload[:note] 	= $evm.object['note'] unless $evm.object['note'].nil? or $evm.object['note'].empty?

uri                     = "schedules"
$evm.object['result']	= ""

client = $evm.instantiate("/Integration/RestClients/Turbonomic?method=#{$evm.object['method']}&uri=#{uri}&payload=#{payload.to_json}")
$evm.object['result'] = client['result']
