#
# Description: <Method description here>
#

values_hash  = {}
begin
  values_hash['no'] = "No"
  values_hash['yes'] = "Yes"
  
  list_values = {
     'sort_by'    => :value,
     'data_type'  => :string,
     'required'   => true,
     'values'     => values_hash,
     'visible'	  => $evm.root['dialog_param_state'] == 'present'
  }
  list_values.each { |key, value| $evm.object[key] = value }
  exit MIQ_OK

rescue => err
  $evm.log(:error, "[#{err}]\n#{err.backtrace.join("\n")}")
  exit MIQ_STOP
end



