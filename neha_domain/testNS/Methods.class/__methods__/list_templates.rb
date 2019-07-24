begin
  vmware_templates = {}
  vmware =  $evm.vmdb('ems').find_by_name('vmware-admin')
  vmware.miq_templates.each do |t|
       vmware_templates[t.id] = t.name
  end

  list_values = {
    'sort_by'    => :value,
    'data_type'  => :string,
    'required'   => true,
    'values'     => vmware_templates
  }
  list_values.each { |key, value| $evm.object[key] = value }

 rescue => err
  $evm.log(:error, "[#{err}]\n#{err.backtrace.join("\n")}")
  exit MIQ_STOP
end
