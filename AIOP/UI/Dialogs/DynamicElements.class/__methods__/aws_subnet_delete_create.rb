#
# Description: <Method description here>
#

values_hash  = {}
begin
  values_hash['present'] = "Create"
  values_hash['absent'] = "Delete"
  
  list_values = {
     'sort_by'    => :value,
     'data_type'  => :string,
     'required'   => true,
     'values'     => values_hash
  }
  list_values.each { |key, value| $evm.object[key] = value }
  exit MIQ_OK

rescue => err
  $evm.log(:error, "[#{err}]\n#{err.backtrace.join("\n")}")
  exit MIQ_STOP
end



