#
# Description: <Method description here>
#

#
# Description: <Method description here>
#
dialog_field = $evm.object

# sort_by: value / description / none
dialog_field["sort_by"] = "description"

# sort_order: ascending / descending
dialog_field["sort_order"] = "ascending"

# data_type: string / integer
dialog_field["data_type"] = "string"

# required: true / false
dialog_field["required"] = true

dialog_field["values"] = { Template_RHEL7"."4_20180318 => "RHEL7.4 TP", Template_RHEL6"."8_20180330_NewBoot => "RHEL 6.8 TP"}
dialog_field["default_value"] = "Chose a Template"
