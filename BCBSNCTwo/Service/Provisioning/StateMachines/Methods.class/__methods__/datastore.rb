#
# Description: <Method description here>
#
begin

drop_down = {}
  provider_id = $evm.root['dialog_provider']
  $evm.log("info", "Provider name is #{provider_id}")
  provider = $evm.vmdb('ems').find_by_id(provider_id)
  storage = provider.storages
  storage.each do |s|
    drop_down['!'] = '-- select from list --'
      drop_down[s.id] = "#{s.name}"
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
