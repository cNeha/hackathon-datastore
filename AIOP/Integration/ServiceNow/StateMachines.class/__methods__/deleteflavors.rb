module Integration
  module ServiceNow
    module StateMachines
      class DeleteFlavors
        def initialize(handle = $evm)
          @handle = handle
          @vo = @handle.instantiate("/General/GenericObjects/ValueDictionary")
          @snow_vo = @handle.instantiate("/Integration/ServiceNow/GenericObjects/ValueDictionary")
        end

        def main
          exit MIQ_OK unless @snow_vo['enabled']
          
          provider = @handle.root['ext_management_system']
          flavors = []
          flavor_id = @handle.root['dialog_flavor_id']

          unless flavor_id.blank?
            flavors << @handle.vmdb(:flavor).find_by_id(flavor_id)
          else
            flavors = provider.flavors.select {|fl| flavor_eligible?(fl) }
          end
          raise "no flavors found: #{flavors.inspect}" if flavors.blank?

          flavors.each do |flavor|

            # query the table for an existing record with flavor.id
            query = {}
            query['id'] = flavor.id
          	servicenow_query = check_flavor_exists_in_servicenow(query)

            #if we got back more than one record for whatever reason then get the first record
            servicenow_query = servicenow_query[0] if servicenow_query.kind_of?(Array)

            servicenow_sysid = servicenow_query['sys_id'] unless servicenow_query.blank?

            if servicenow_sysid
              delete_flavor_from_servicenow(servicenow_sysid)
            end
          end
          
          exit MIQ_OK
        end
        
        def get_table_name
          @handle.object['table_name']
        end
        
        def check_flavor_exists_in_servicenow(query)
          client = @handle.instantiate("/Integration/RestClients/ServiceNow?method=get&table_name=#{get_table_name}&query=#{query.to_json}")
          JSON.parse(client['result'])
        end
        
        def delete_flavor_from_servicenow(servicenow_sysid)
          @handle.instantiate("/Integration/RestClients/ServiceNow?method=delete&table_name=#{get_table_name}&sysid=#{servicenow_sysid}")
        end
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
	Integration::ServiceNow::StateMachines::DeleteFlavors.new.main
end
