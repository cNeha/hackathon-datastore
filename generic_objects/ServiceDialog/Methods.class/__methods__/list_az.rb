begin
  $evm.log("info", "Value of #{$evm.root['dialog_check_list']}")
   if $evm.root['dialog_check_list'] == 't'
       $evm.object['visible'] = true
      availability_zones = {}
      aws = $evm.vmdb('ems').find_by_name('aws')
      aws.availability_zones.each do |az|
        availability_zones['!'] = "--select from the list--"
        availability_zones[az.name] = az.name
     end
      list_values = {
                 'sort_by'    => :value,
                 'data_type'  => :string,
                 'required' => true,
                 'values' =>  availability_zones
                }
    list_values.each { |key, value| $evm.object[key] = value }
    $evm.log("info", "LIST VALUES are #{list_values}")
   else
      $evm.object['visible'] = false
  end
 rescue => err
  $evm.log(:error, "[#{err}]\n#{err.backtrace.join("\n")}")
  exit MIQ_STOP
end
