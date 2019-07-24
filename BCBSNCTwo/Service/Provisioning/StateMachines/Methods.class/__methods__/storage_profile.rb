#
# Description: <Method description here>
#
begin

drop_down = {}
  cluster_name = $evm.vmdb(:storage_profile).all
  cluster_name.each do |cn|
    drop_down['!'] = '-- select from list --'
      drop_down[cn.id] = "#{cn.name}"
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
