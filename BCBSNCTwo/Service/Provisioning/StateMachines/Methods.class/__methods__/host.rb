#
# Description: <Method description here>
#
begin

drop_down = {}
  # provider_id = $evm.root['dialog_provider']
  #$evm.log("info", "Provider name is #{provider_id}")
  #provider = $evm.vmdb('ems').find_by_id(provider_id)
  #host = $evm.vmdb(:host).all
  cluster_id = $evm.root['dialog_placement_cluster_name']
  $evm.log('info', "CLUSTER ID IS #{cluster_id}")
  cluster = $evm.vmdb('ems_cluster').find_by_id(cluster_id)
  host = cluster.hosts
  host.each do |h|
    drop_down['!'] = '-- select from list --'
      drop_down[h.id] = "#{h.name}"
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
