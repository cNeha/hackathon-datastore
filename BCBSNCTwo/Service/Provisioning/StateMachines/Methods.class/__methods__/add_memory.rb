#
# Description: <Method description here>
#
dialog_field = $evm.object

# sort_by: value / description / none
dialog_field["sort_by"] = "value"

# sort_order: ascending / descending
dialog_field["sort_order"] = "ascending"

# data_type: string / integer
dialog_field["data_type"] = "integer"

# required: true / false
dialog_field["required"] = true

dialog_field["values"] = {2048 => "2GB", 4096 => "4GB", 16384 => "16GB"}
dialog_field["default_value"] = 2048
