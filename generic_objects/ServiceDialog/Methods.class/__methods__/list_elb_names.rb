
begin
  if $evm.root['dialog_load_balancer_type'] == '1'
    $evm.object['visible'] = true
  else
    $evm.object['visible'] = false
  end
  load_balancers = {}
  elb =  $evm.vmdb('load_balancer').all.each do |elb|
        load_balancers['!'] = '-- select from list --'
       load_balancers[elb.id] = elb.name
  end

  list_values = {
    'sort_by'    => :value,
    'data_type'  => :string,
    'required'   => true,
    'values'     => load_balancers
  }
  list_values.each { |key, value| $evm.object[key] = value }

 rescue => err
  $evm.log(:error, "[#{err}]\n#{err.backtrace.join("\n")}")
  exit MIQ_STOP
end
