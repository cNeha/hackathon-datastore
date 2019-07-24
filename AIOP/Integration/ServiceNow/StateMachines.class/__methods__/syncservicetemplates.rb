module Integration
  module ServiceNow
    module StateMachines
      class SyncServiceTemplates
        def initialize(handle = $evm)
          @handle = handle
          @vo = @handle.instantiate("/General/GenericObjects/ValueDictionary")
          @snow_vo = @handle.instantiate("/Integration/ServiceNow/GenericObjects/ValueDictionary")
        end

        def main
          exit MIQ_OK unless @snow_vo['enabled']
          
          delete_templates
          service_templates = []
          @handle.log(:info, "===ServiceNow: service_template_provision_task: #{@handle.root['service_template_provision_task']}")
          @handle.log(:info, "===ServiceNow: service: #{@handle.root['service']}")
          @handle.log(:info, "===ServiceNow: dialog_service_template_id: #{@handle.root['dialog_service_template_id']}")

          if @handle.root['service_template_provision_task'] || @handle.root['service']
            service_template_id = @handle.root['dialog_service_template_id']
            unless service_template_id.blank?
              service_templates << @handle.vmdb(:service_template).find_by_id(service_template_id)
            else
              service_templates = @handle.vmdb(:service_template).all.select {|st| service_template_eligible?(st) }
            end
          else
            service_templates = @handle.vmdb(:service_template).all.select {|st| service_template_eligible?(st) }
          end
        
          raise "no service_templates found: #{service_templates.inspect}" if service_templates.blank?

          service_templates.each do |service_template|
            payload = build_payload(service_template)
            servicenow_sysid = get_system_id(service_template)

            if servicenow_sysid
              begin
              	client = @handle.instantiate("/Integration/RestClients/ServiceNow?method=patch&table_name=#{get_table_name}&sys_id=#{servicenow_sysid}&payload=#{payload.to_json}")
          	  	@handle.object['result'] = JSON.Parse(client['result'])
              rescue
              end
            else
              client = $evm.instantiate("/Integration/RestClients/ServiceNow?method=post&table_name=#{get_table_name}&payload=#{payload.to_json}")
          	  @handle.object['result'] = JSON.parse(client['result'])
            end
          end
          
          exit MIQ_OK
        end
        
        def delete_templates
          client = @handle.instantiate("/Integration/RestClients/ServiceNow?method=get&table_name=#{get_table_name}")
          servicenow_query = JSON.parse(client['result'])['result']
          servicenow_query.each do |result|
          	template = @handle.vmdb(:service_template).find_by_id(result['u_id'])
            if template.nil? || !service_template_eligible?(template)
              client = @handle.instantiate("/Integration/RestClients/ServiceNow?method=delete&sys_id=#{result['sys_id']}&table_name=#{get_table_name}")
            end
          end
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

        def get_table_name
          @handle.object['table_name']
        end

        def service_template_eligible?(service_template)
          # example to only sync service_templates tagged with environment
          #return false if service_template.tags(:environment).nil?
          # disregard service_template that is not displayable
          return false unless service_template.template_valid
          return true
        end

        def build_payload(obj, payload = {})
          payload = {
            :u_description                  => obj.description,
            :u_guid                         => obj.guid,
            :u_id                           => obj.id,
            :u_name                         => obj.name,
            :u_provider_type                => obj.prov_type,
            :u_service_template_catalog_id  => obj.service_template_catalog_id,
            :u_service_type                 => obj.service_type,
            :u_template_valid               => obj.template_valid,
            :u_type                         => obj.type
          }
          # ServiceNow does not like nil values using compact to remove them
          return payload.compact
        end
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
	Integration::ServiceNow::StateMachines::SyncServiceTemplates.new.main
end
