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

    subnets = ec2.describe_subnets

    subnets.subnets.each do |subnet|
      cidr_block = subnet.cidr_block
      values_hash[cidr_block] = cidr_block
      subnet.tags.each do |tag|
        if tag[:key] == 'Name'
          values_hash[cidr_block] = "#{cidr_block} | #{tag[:value]}"
        end
      end
    end

    list_values = {
       'sort_by'    => :value,
       'data_type'  => :string,
       'required'   => true,
       'values'     => values_hash,
       'visible' 	=> $evm.root['dialog_param_state'] == 'absent'
    }
    list_values.each { |key, value| $evm.object[key] = value }
  else
    list_values = {
       'sort_by'    => :value,
       'data_type'  => :string,
       'required'   => true,
       'visible' 	=> $evm.root['dialog_param_state'] == 'absent'
    }
    list_values.each { |key, value| $evm.object[key] = value }
  end
  exit MIQ_OK

rescue => err
  #$evm.log(:error, "[#{err}]\n#{err.backtrace.join("\n")}")
  exit MIQ_STOP
end
