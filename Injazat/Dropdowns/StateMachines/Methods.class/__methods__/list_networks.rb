#
# Description: <Method description here>
#

dialog_field = $evm.object
dialog_field['sort_by'] = 'description'
dialog_field['sort_order'] = 'ascending'
dialog_field['data_type'] = 'string'

dialog_field['required'] = true
dialog_field['values'] = nil

networks_hash ={}
all_network_provider = $evm.vmdb(:ems_network).all()
network_provider = all_network_provider.select {|x| x.tagged_with?("provider_type", "nuage")}.first
networks = network_provider.cloud_subnets
networks.each do |network|
  networks_hash[network.ems_ref] = network.name 
end

dialog_field['values'] = networks_hash
