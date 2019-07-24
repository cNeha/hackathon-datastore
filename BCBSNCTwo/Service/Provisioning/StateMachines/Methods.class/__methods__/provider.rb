#
# Description: <Method description here>
#
begin

drop_down = {}
#  provider = $evm.vmdb(:ems).all
  provider = $evm.vmdb(:ManageIQ_Providers_Vmware_InfraManager).all.each do |p|
#  provider.each do |p|
    drop_down['!'] = '-- select from list --'
      drop_down[p.id] = "#{p.name}"
    end
 

  list_values = {
    'sort_by'    => :value,
    'data_type'  => :string,
    'required'   => true,
    'values'     => drop_down
  }
  list_values.each { |key, value| $evm.object[key] = value }

 rescue => err
  $evm.log(:error, "[#{err}]\n#{err.backtrace.join("\n")}")
  exit MIQ_STOP
end


