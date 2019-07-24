=begin
name		(O)
startDate	(O)
endDate		(O)
startTime	(O)
endTime		(O)
color		(O)
group		(O)
action		(O)
actionMode	(O)
recur		(O)
note		(O)
=end

payload = $evm.object['payload'].nil? ? {} : $evm.object['payload']



payload[:name] 			= $evm.object['name'] unless $evm.object['name'].nil? or $evm.object['name'].empty?
payload[:startDate] 	= $evm.object['startDate'] unless $evm.object['startDate'].nil? or $evm.object['startDate'].empty?
payload[:endDate] 		= $evm.object['endDate'] unless $evm.object['endDate'].nil? or $evm.object['endDate'].empty?
payload[:startTime] 	= $evm.object['startTime'] unless $evm.object['startTime'].nil? or $evm.object['startTime'].empty?
payload[:endTime] 		= $evm.object['endTime'] unless $evm.object['endTime'].nil? or $evm.object['endTime'].empty?
payload[:color] 		= $evm.object['color'] unless $evm.object['color'].nil? or $evm.object['color'].empty?
payload[:group] 		= $evm.object['group'] unless $evm.object['group'].nil? or $evm.object['group'].empty?
payload[:action] 		= $evm.object['action'] unless $evm.object['action'].nil? or $evm.object['action'].empty?
payload[:actionMode] 	= $evm.object['actionMode'] unless $evm.object['actionMode'].nil? or $evm.object['actionMode'].empty?
payload[:recur] 		= $evm.object['recur'] unless $evm.object['recur'].nil? or $evm.object['recur'].empty?
payload[:note] 			= $evm.object['note'] unless $evm.object['note'].nil? or $evm.object['note'].empty?

uri                     = "schedules#{$evm.object['uuid']}"
$evm.object['result']	= ""

client = $evm.instantiate("/Integration/RestClients/Turbonomic?method=#{$evm.object['method']}&uri=#{uri}&payload=#{payload.to_json}")
$evm.object['result'] = client['result']
