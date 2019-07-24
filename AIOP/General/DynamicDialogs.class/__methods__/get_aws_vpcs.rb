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

    vpcs = ec2.describe_vpcs

    vpcs.vpcs.each do |vpc|
      vpc_id = vpc.vpc_id
      values_hash[vpc_id] = vpc.cidr_block
      vpc.tags.each do |tag|
        if tag[:key] == 'Name'
          values_hash[vpc_id] = "#{vpc.cidr_block} | #{tag[:value]}"
        end
      end
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
  #$evm.log(:error, "[#{err}]\n#{err.backtrace.join("\n")}")
  exit MIQ_STOP
end
