module Integration
  module ServiceNow
    module StateMachines
      class SyncAvailabilityZones
        def initialize(handle = $evm)
          @handle = handle
          @vo = @handle.instantiate("/General/GenericObjects/ValueDictionary")
          @snow_vo = @handle.instantiate("/Integration/ServiceNow/GenericObjects/ValueDictionary")
        end

        def main
          exit MIQ_OK unless @snow_vo['enabled']
          @handle.log(:info, "===ServiceNow: Beginning SyncAvailabilityZones")
          delete_zones
       
          zones = []
          zones = @handle.vmdb(:availability_zone).all
          

          zones.each do |zone|
            payload = build_payload(zone)
            servicenow_sysid = get_system_id(zone)
			
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
        
        def delete_zones
          client = @handle.instantiate("/Integration/RestClients/ServiceNow?method=get&table_name=#{get_table_name}")
          servicenow_query = JSON.parse(client['result'])['result']
  
          servicenow_query.each do |result|
          	zone = @handle.vmdb(:availability_zone).find_by_id(result['u_id'])
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
            :u_id           => obj.id,
            :u_name         => obj.name,
            :u_type         => obj.type,
            :u_ext_management_id    => obj.try(:ext_management_system).try(:id),
            :u_provider     		=> obj.try(:ext_management_system).try(:name),
            :u_ems_ref				=> obj.ems_ref,
            :u_ems_id				=> obj.ems_id
          }
          # ServiceNow does not like nil values using compact to remove them
          return payload.compact
        end
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
	Integration::ServiceNow::StateMachines::SyncAvailabilityZones.new.main
end
