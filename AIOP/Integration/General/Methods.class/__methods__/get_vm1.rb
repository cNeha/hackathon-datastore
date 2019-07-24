#
#            Automate Method
#
$evm.log("info", "dropDown Automate Method Started")

dialog_field = $evm.object
 
# sort_by: value / description / none
dialog_field["sort_by"] = "value"
 
# sort_order: ascending / descending
#dialog_field["sort_order"] = "ascending"
 
# data_type: string / integer
#dialog_field["data_type"] = "integer"
 
# required: true / false
dialog_field["required"] = "true"

# required: true / false
dialog_field["visible"]=true
 
values={}
values[nil] = "Select VM"
$evm.vmdb('vm').all.each { |x| values[x.name] = x.name }
#$evm.vmdb('vm').all.each { |x| values[x.attributes] = x.attributes }
dialog_field["values"]=values

#
$evm.log("info", "dropDown Automate Method Ended")
exit MIQ_OK
