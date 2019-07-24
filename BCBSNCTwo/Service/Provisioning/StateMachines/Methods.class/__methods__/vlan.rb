#
# Description: <Method description here>
#
# To find all the datacenters in the vmware 

begin

drop_down = {}
  host_id = $evm.root['dialog_placement_host_name']
  host = $evm.vmdb('host').find_by_id(host_id)
  lan = host.lans  
  lan.each do |l|
    drop_down['!'] = '-- select from list --'
      drop_down[l.id] = "#{l.name}"
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
