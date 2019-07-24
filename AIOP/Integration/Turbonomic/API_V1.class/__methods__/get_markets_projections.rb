payload = $evm.object['payload'].nil? ? {} : $evm.object['payload']

uri                     = "martkets/#{$evm.object['uuid']}"
$evm.object['result']	= ""

unless $evm.object['entity_type'].nil?
  uri << "/#{$evm.object['entity']}"
end

unless $evm.object['cluster_uuid'].nil?
  uri << "/#{$evm.object['cluster_uuid']}"
end

uri << "/projections"

client = $evm.instantiate("/Integration/RestClients/Turbonomic?method=#{$evm.object['method']}&uri=#{uri}&payload=#{payload.to_json}")
$evm.object['result'] = client['result']
