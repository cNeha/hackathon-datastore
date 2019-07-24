#
# Description: <Method description here>
#

dialog_field = $evm.object
dialog_field['sort_by'] = 'description'
dialog_field['sort_order'] = 'ascending'
dialog_field['data_type'] = 'string'

dialog_field['required'] = true
dialog_field['values'] = nil

templates_hash ={}
app_class = $evm.vmdb(:generic_object_definition).find_by_name("Application")
apps = $evm.vmdb(:generic_object).where(:generic_object_definition_id => app_class.id)

apps.each do |app|
  templates_hash[app.attributes['properties']['application_id']] = app.name  
end

dialog_field['values'] = templates_hash
