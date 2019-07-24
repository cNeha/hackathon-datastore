module Integration
  module ServiceNow
    module StateMachines
      class SyncCloudSubnets
        def initialize(handle = $evm)
          @handle = handle
          @vo = @handle.instantiate("/General/GenericObjects/ValueDictionary")
          @snow_vo = @handle.instantiate("/Integration/ServiceNow/GenericObjects/ValueDictionary")
        end

        def main
          exit MIQ_OK unless @snow_vo['enabled']
          
          delete_subnets
          
          subnets = []
          subnets = @handle.vmdb(:cloud_subnet).all

          subnets.each do |subnet|
            payload = build_payload(subnet)
            servicenow_sysid = get_system_id(subnet)
			
            unless servicenow_sysid.nil?
              client = @handle.instantiate("/Integration/RestClients/ServiceNow?method=patch&sys_id=#{servicenow_sysid}&table_name=#{get_table_name}&payload=#{payload.to_json}")
              @handle.object['result'] = JSON.parse(client['result'])
            else
              client = @handle.instantiate("/Integration/RestClients/ServiceNow?method=post&table_name=#{get_table_name}&payload=#{payload.to_json}")
              @handle.object['result'] = JSON.parse(client['result'])
            end
          end
       
          exit MIQ_OK
        end
        
        def delete_subnets
          client = @handle.instantiate("/Integration/RestClients/ServiceNow?method=get&table_name=#{get_table_name}")
          servicenow_query = JSON.parse(client['result'])['result']
  
          servicenow_query.each do |result|
          	zone = @handle.vmdb(:cloud_subnet).find_by_id(result['u_id'])
            if zone.nil?
              client = @handle.instantiate("/Integration/RestClients/ServiceNow?method=delete&sys_id=#{result['sys_id']}&table_name=#{get_table_name}")
            end
          end
        end

        def get_table_name
          @handle.object['table_name']
        end        
        
        def get_system_id(obj)
          query = {}
          query['u_id'] = obj.id
          client = @handle.instantiate("/Integration/RestClients/ServiceNow?method=get&table_name=#{get_table_name}&query=#{query.to_json}")
          servicenow_query = JSON.parse(client['result'])['result']

          #if we got back more than one record for whatever reason then get the first record
          servicenow_query = servicenow_query[0] if servicenow_query.kind_of?(Array)
          servicenow_query['sys_id'] unless servicenow_query.blank?
        end

        def build_payload(obj, payload = {})
          payload = {
            :u_id           		=> obj.id,
            :u_name         		=> obj.name,
            :u_type         		=> obj.type,
            :u_ems_ref				=> obj.ems_ref,
            :u_ems_id				=> obj.ems_id,
            :u_ems_parent_id		=> obj.cloud_network.ext_management_system.parent_ems_id,
            :u_availability_zone_id	=> obj.availability_zone_id,
            :u_cloud_network_id		=> obj.cloud_network_id,
            :u_cidr					=> obj.cidr
          }
          # ServiceNow does not like nil values using compact to remove them
          return payload.compact
        end
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
	Integration::ServiceNow::StateMachines::SyncCloudSubnets.new.main
end
