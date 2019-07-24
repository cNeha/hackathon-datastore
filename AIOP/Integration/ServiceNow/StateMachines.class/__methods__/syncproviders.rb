module Integration
  module ServiceNow
    module StateMachines
      class SyncProviders
        def initialize(handle = $evm)
          @handle = handle
          @vo = @handle.instantiate("/General/GenericObjects/ValueDictionary")
          @snow_vo = @handle.instantiate("/Integration/ServiceNow/GenericObjects/ValueDictionary")
        end

        def main
          exit MIQ_OK unless @snow_vo['enabled']
          
          delete_providers
          
          providers = []
          if !@handle.object['provider_id'].nil?
            providers << @handle.vmdb(:ems_cloud).find_by_id(@handle.object['provider_id'])
          elsif !@handle.root['ext_management_system'].nil?
          	providers << @handle.root['ext_management_system']
          else
            providers = @handle.vmdb(:ems_cloud).all
          end
          @handle.log(:info, "===ServiceNow: dialog #{@handle.root['ext_management_system'].inspect}")

          providers.each do |provider|
            payload = build_payload(provider)
            servicenow_sysid = provider.custom_get(:servicenow_provider_sysid)
			
            begin
              unless servicenow_sysid.nil?
                client = @handle.instantiate("/Integration/RestClients/ServiceNow?method=patch&sys_id=#{servicenow_sysid}&table_name=#{get_table_name}&payload=#{payload.to_json}")
                @handle.object['result'] = JSON.parse(client['result'])
              else
                client = @handle.instantiate("/Integration/RestClients/ServiceNow?method=post&table_name=#{get_table_name}&payload=#{payload.to_json}")
                @handle.object['result'] = JSON.parse(client['result'])
              end
              set_custom_attributes(provider, @handle.object['result'])
            rescue
            end
          end
       
          exit MIQ_OK
        end
        
        def delete_providers
          client = @handle.instantiate("/Integration/RestClients/ServiceNow?method=get&table_name=#{get_table_name}")
          servicenow_query = JSON.parse(client['result'])['result']
  
          servicenow_query.each do |result|
          	provider = @handle.vmdb(:ems_cloud).find_by_id(result['u_id'])
            if provider.nil?
              client = @handle.instantiate("/Integration/RestClients/ServiceNow?method=delete&sys_id=#{result['sys_id']}&table_name=#{get_table_name}")
            end
          end
        end

        def get_table_name
          @handle.object['table_name']
        end

        def set_custom_attributes(obj, servicenow_result)
          now = Time.now.strftime('%Y%m%d-%H%M%S').to_s
          obj.custom_set(:servicenow_provider_update, now)
          obj.custom_set(:servicenow_provider_tablename, get_table_name)
          obj.custom_set(:servicenow_provider_sysid, servicenow_result['result']['sys_id'].to_s)
        end

        def build_payload(obj, payload = {})
          payload = {
            :u_id           => obj.id,
            :u_name         => obj.name,
            :u_type         => obj.type
          }
          # ServiceNow does not like nil values using compact to remove them
          return payload.compact
        end
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
	Integration::ServiceNow::StateMachines::SyncProviders.new.main
end
