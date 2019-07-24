#
#            Automate Method for list down VM Info
#
$evm.log("info", "dropDown VM List Method Started")
dialog_field = $evm.object

dialog_field["sort_by"] = "value"
dialog_field["required"] = "true"
dialog_field["visible"]=true
 
values={}
values[nil] = "Select VM"

$evm.vmdb('vm').all.each { |x| values[x.name] = x.name }

dialog_field["values"]=values

#
$evm.log("info", "dropDown Automate Method Ended")
exit MIQ_OK
