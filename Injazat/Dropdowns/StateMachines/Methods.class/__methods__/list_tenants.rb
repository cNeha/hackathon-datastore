dialog_field = $evm.object
dialog_field['sort_by'] = 'description'
dialog_field['sort_order'] = 'ascending'
dialog_field['data_type'] = 'string'

dialog_field['required'] = true
dialog_field['values'] = nil

tenants_hash ={}
tenant_class = $evm.vmdb(:generic_object_definition).find_by_name("Tenant")
tenants = $evm.vmdb(:generic_object).where(:generic_object_definition_id => tenant_class.id)

tenants.each do |tenant|
  tenants_hash[tenant.name] = tenant.name 
end

dialog_field['values'] = tenants_hash
