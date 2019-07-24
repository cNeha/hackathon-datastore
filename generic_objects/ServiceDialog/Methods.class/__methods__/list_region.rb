begin
  $evm.log("info", "Value of #{$evm.root['dialog_check_list']}")
   if $evm.root['dialog_check_list'] == 't'
       $evm.object['visible'] = true
      aws = $evm.vmdb('ems').find_by_name('aws')
      region = aws.provider_region
      list_values = {
                 'data_type'  => :string,
                 'value' => region
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
