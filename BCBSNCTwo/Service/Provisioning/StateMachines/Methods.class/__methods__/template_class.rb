#
# Description: <Method description here>
#
begin

drop_down = {'!' => '-- select from list --'}

#provider = $evm.vmdb(:ManageIQ_Providers_Vmware_InfraManager).first
#provider = $evm.vmdb(:ManageIQ_Providers_Vmware_InfraManager).all.each do |provider|
provider_id = $evm.root['dialog_provider']
$evm.log("info", "Provider name is #{provider_id}")
provider = $evm.vmdb('ems').find_by_id(provider_id)

provider.miq_templates.each { |tn| drop_down[tn.id] = "#{tn.name}" }
list_values = {
  'sort_by' => :value,
  'data_type' => :string,
  'required' => true,
  'values' => drop_down
}
list_values.each { |key, value| $evm.object[key] = value }

 rescue => err
  $evm.log(:error, "[#{err}]\n#{err.backtrace.join("\n")}")
 exit MIQ_STOP
end
