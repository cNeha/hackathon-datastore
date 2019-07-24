values_hash  = {}
values_hash['!'] = '-- select from list --'
begin
  providers = $evm.vmdb('ems_cloud').all
  providers.each do |provider|
	if provider.type == "ManageIQ::Providers::Amazon::CloudManager"
      values_hash[provider.provider_region] = "#{provider.name} | #{provider.provider_region}"
    end
  end

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
