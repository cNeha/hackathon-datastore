require 'aws-sdk'

vo = $evm.instantiate("/General/GenericObjects/ValueDictionary")
cred = Aws::Credentials.new(vo.decrypt('aws_access_key'), vo.decrypt('aws_secret_key'))

values_hash  = {}
values_hash['!'] = '-- select from list --'

region = $evm.root['dialog_param_region']
$evm.log(:error, "AWS Region: #{region}")

begin
  unless region == '!'
    ec2 = Aws::EC2::Client.new(
      region: region,
      credentials: cred
      )

    azs = ec2.describe_availability_zones

    azs.availability_zones.each do |az|
      az_name = az.zone_name
      values_hash[az_name] = az_name
    end

    list_values = {
       'sort_by'    => :value,
       'data_type'  => :string,
       'required'   => true,
       'values'     => values_hash
    }
    list_values.each { |key, value| $evm.object[key] = value }
  end
  exit MIQ_OK

rescue => err
  $evm.log(:error, "[#{err}]\n#{err.backtrace.join("\n")}")
  exit MIQ_STOP
end

