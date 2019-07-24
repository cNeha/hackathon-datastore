# To find all the datacenters in the vmware 

begin

drop_down = {}
  provider_id = $evm.root['dialog_provider']
  $evm.log("info", "Provider name is #{provider_id}")
  provider = $evm.vmdb('ems').find_by_id(provider_id)
  data_center = provider.ems_folders.select { |f| f.type == 'Datacenter' }
   data_center.each do |dc|
    drop_down['!'] = '-- select from list --'
      drop_down[dc.id] = "#{dc.name}"
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
