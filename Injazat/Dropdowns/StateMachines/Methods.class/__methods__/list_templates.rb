#
# Description: <Method description here>
#

dialog_field = $evm.object
dialog_field['sort_by'] = 'description'
dialog_field['sort_order'] = 'ascending'
dialog_field['data_type'] = 'string'

dialog_field['required'] = true
dialog_field['values'] = nil

templates_hash = {
 "RHEL7" => "rhel7",
  "Windows 2016" => "windows2016"
 }

dialog_field['values'] = templates_hash
