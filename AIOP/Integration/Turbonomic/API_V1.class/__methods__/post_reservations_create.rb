=begin
reservationName		(R)
count				(R)
templateName		(R)
deploymentProfile	(O)
deployDate			(O)
reservationDate		(O)
segmentationUuid[]	(O)
=end

payload = {
  :reservationName 	=> $evm.object['reservationName'],
  :count 			=> $evm.object['count'],
  :templateName 	=> $evm.object['templateName']
}
payload[:deploymentProfile] 	= $evm.object['deploymentProfile'] unless $evm.object['deploymentProfile'].nil? or $evm.object['deploymentProfile'].empty?
payload[:deployDate] 			= $evm.object['deployDate'] unless $evm.object['deployDate'].nil? or $evm.object['deployDate'].empty?
payload[:reservationDate] 		= $evm.object['reservationDate'] unless $evm.object['reservationDate'].nil? or $evm.object['reservationDate'].empty?
payload[:segmentationUuid[]] 	= $evm.object['segmentationUuid'] unless $evm.object['segmentationUuid'].nil? or $evm.object['segmentationUuid'].empty?

uri                     = "reservations"
$evm.object['result']	= ""

client = $evm.instantiate("/Integration/RestClients/Turbonomic?method=#{$evm.object['method']}&uri=#{uri}&payload=#{payload.to_json}")
$evm.object['result'] = client['result']
