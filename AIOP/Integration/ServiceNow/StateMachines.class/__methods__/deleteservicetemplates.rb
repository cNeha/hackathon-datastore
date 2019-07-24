module Integration
  module ServiceNow
    module StateMachines
      class DeleteServiceTemplates
        def initialize(handle = $evm)
          @handle = handle
          @vo = @handle.instantiate("/General/GenericObjects/ValueDictionary")
          @snow_vo = @handle.instantiate("/Integration/ServiceNow/GenericObjects/ValueDictionary")
        end

        def main
          exit MIQ_OK unless @snow_vo['enabled']
          
          if @handle.root['service_template_provision_task'] || @handle.root['service']
            service_template_id = @handle.root['dialog_service_template_id']
            unless service_template_id.blank?
              service_templates = []
              service_templates << @handle.vmdb(:service_template).find_by_id(service_template_id)
            else
              service_templates = @handle.vmdb(:service_template).all
            end
          else
            service_templates = @handle.vmdb(:service_template).all
          end

          service_templates.each do |service_template|

            # query the table for an existing record with service_template.id
            query = {}
            query['id'] = service_template.id
            
            servicenow_query = get_service_template_from_servicenow(query)
    
            #if we got back more than one record for whatever reason then get the first record
            servicenow_query = servicenow_query[0] if servicenow_query.kind_of?(Array)

            servicenow_sysid = servicenow_query['sys_id'] unless servicenow_query.blank?

            if servicenow_sysid
              delete_template_from_servicenow(servicenow_sysid)
            end
          end

          if @handle.root['service_template_provision_task']
            @handle.root['service_template_provision_task'].destination.remove_from_vmdb
          end
          
          exit MIQ_OK
        end
        
        def get_table_name
          @handle.object['table_name']
        end

        def set_custom_attributes(template)
          template.custom_set(:servicenow_miq_template_update, nil)
          template.custom_set(:servicenow_miq_template_tablename, nil)
          template.custom_set(:servicenow_miq_template_sysid, nil)
        end
        
        def delete_template_from_servicenow(servicenow_sysid)
          @handle.instantiate("/Integration/RestClients/ServiceNow?method=delete&table_name=#{get_table_name}&sysid=#{servicenow_sysid}")
        end
        
        def get_service_template_from_servicenow(query)
          client = @handle.instantiate("/Integration/RestClients/ServiceNow?method=get&table_name=#{get_table_name}&query=#{query.to_json}")
          JSON.parse(client['result'])
        end
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
	Integration::ServiceNow::StateMachines::DeleteServiceTemplates.new.main
end
