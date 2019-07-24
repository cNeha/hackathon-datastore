module Integration
  module ServiceNow
    module StateMachines
      class SyncFlavors
        def initialize(handle = $evm)
          @handle = handle
          @vo = @handle.instantiate("/General/GenericObjects/ValueDictionary")
          @snow_vo = @handle.instantiate("/Integration/ServiceNow/GenericObjects/ValueDictionary")
        end

        def main
          exit MIQ_OK unless @snow_vo['enabled']
          
          delete_flavors
          unless @handle.object['provider_id']
            provider = @handle.vmdb(:ems_cloud).find_by_id(@handle.object['provider_id'])
          else
          	provider = @handle.root['ext_management_system']
          end
          flavors = []
          flavor_id = @handle.root['dialog_flavor_id']

          if !flavor_id.blank?
            flavors << @handle.vmdb(:flavor).find_by_id(flavor_id)
          elsif !provider.nil?
            flavors << provider.flavors.select {|fl| flavor_eligible?(fl) }
          else
            flavors = @handle.vmdb(:flavor).all.select {|fl| flavor_eligible?(fl) }
          end
          raise "no flavors found: #{flavors.inspect}" if flavors.blank?

          flavors.each do |flavor|
            payload = build_payload(flavor)
            servicenow_sysid = get_system_id(flavor)

            unless servicenow_sysid.nil?
              begin
              	client = @handle.instantiate("/Integration/RestClients/ServiceNow?method=patch&sys_id=#{servicenow_sysid}&table_name=#{get_table_name}&payload=#{payload.to_json}")
          	  	@handle.object['result'] = JSON.parse(client['result'])
              rescue
                @handle.log(:error, "===ServiceNow: Error in modifing record")
              end
            else
              client = @handle.instantiate("/Integration/RestClients/ServiceNow?method=post&table_name=#{get_table_name}&payload=#{payload.to_json}")
          	  @handle.object['result'] = JSON.parse(client['result'])
            end
          end
          exit MIQ_OK
        end
        
        def delete_flavors
          client = @handle.instantiate("/Integration/RestClients/ServiceNow?method=get&table_name=#{get_table_name}")
          servicenow_query = JSON.parse(client['result'])['result']
  
          servicenow_query.each do |result|
          	flavor = @handle.vmdb(:flavor).find_by_id(result['u_id'])
            if flavor.nil? || !flavor.enabled
              client = @handle.instantiate("/Integration/RestClients/ServiceNow?method=delete&sys_id=#{result['sys_id']}&table_name=#{get_table_name}")
            end
          end
        end

        def get_table_name
          @handle.object['table_name']
        end

        def flavor_eligible?(flavor)
          return false unless flavor.ext_management_system || flavor.enabled
          return true
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
            :u_cpus         		=> obj.cpus,
            :u_description  		=> obj.description,
            :u_enabled      		=> obj.enabled,
            :u_id           		=> obj.id,
            :u_memory       		=> obj.memory / 1024**2,
            :u_name         		=> obj.name,
            :u_ext_management_id    => obj.try(:ext_management_system).try(:id),
            :u_provider     		=> obj.try(:ext_management_system).try(:name),
            :u_type         		=> obj.type,
            :u_vendor       		=> obj.try(:ext_management_system).try(:vendor)
          }
          # ServiceNow does not like nil values using compact to remove them
          return payload.compact
        end
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
	Integration::ServiceNow::StateMachines::SyncFlavors.new.main
end
