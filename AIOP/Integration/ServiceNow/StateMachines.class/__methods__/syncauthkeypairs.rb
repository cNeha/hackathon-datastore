module Integration
  module ServiceNow
    module StateMachines
      class SyncAuthKeyPairs
        def initialize(handle = $evm)
          @handle = handle
          @vo = @handle.instantiate("/General/GenericObjects/ValueDictionary")
          @snow_vo = @handle.instantiate("/Integration/ServiceNow/GenericObjects/ValueDictionary")
        end

        def main
          exit MIQ_OK unless @snow_vo['enabled']
          providers = @handle.vmdb(:ems_cloud).all
          
          providers.each do |provider|
            @handle.log(:info, "===ServiceNow: provider #{provider.name}")
          	delete_key_pair(provider)
          
            key_pairs = provider.key_pairs

            key_pairs.each do |kp|
              @handle.log(:info, "===ServiceNow: key pair #{kp.name}")
              payload = build_payload(kp)
              servicenow_sysid = get_system_id(kp)
              
              unless servicenow_sysid.nil?
                client = @handle.instantiate("/Integration/RestClients/ServiceNow?method=patch&sys_id=#{servicenow_sysid}&table_name=#{get_table_name}&payload=#{payload.to_json}")
                @handle.object['result'] = JSON.parse(client['result'])
              else
                client = @handle.instantiate("/Integration/RestClients/ServiceNow?method=post&table_name=#{get_table_name}&payload=#{payload.to_json}")
                @handle.object['result'] = JSON.parse(client['result'])
              end

            end
          end
          exit MIQ_OK
        end
        
        def delete_key_pair(provider)
          provider.key_pairs.each do |kp|
            client = @handle.instantiate("/Integration/RestClients/ServiceNow?method=get&table_name=#{get_table_name}")
            servicenow_query = JSON.parse(client['result'])['result']

            if !servicenow_query.empty? && !servicenow_query.any? {|h| h['u_id'] == kp.id.to_s}
              result = servicenow_query.detect {  |h| h['u_id'] == kp.id.to_s }
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
            :u_resource_id	=> obj.resource_id
          }
          # ServiceNow does not like nil values using compact to remove them
          return payload.compact
        end
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
	Integration::ServiceNow::StateMachines::SyncAuthKeyPairs.new.main
end
