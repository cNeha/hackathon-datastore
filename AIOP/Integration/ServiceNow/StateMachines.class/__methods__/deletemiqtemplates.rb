module Integration
  module ServiceNow
    module StateMachines
      class DeleteMIQTemplates
        def initialize(handle = $evm)
          @handle = handle
          @vo = @handle.instantiate("/General/GenericObjects/ValueDictionary")
          @snow_vo = @handle.instantiate("/Integration/ServiceNow/GenericObjects/ValueDictionary")
        end

        def main
          exit MIQ_OK unless @snow_vo['enabled']
          
          miq_templates = []
          if @handle.root['service_template_provision_task'] || @handleroot['service']
            miq_template_id = @handle.root['dialog_miq_template_id']
            unless miq_template_id.blank?
              miq_templates << @handle.vmdb(:miq_template).find_by_id(miq_template_id)
            else
              miq_templates = @handle.vmdb(:miq_template).all
            end
          elsif @handle.root['vm'].nil?
            miq_templates = @handle.vmdb(:miq_template).all
          else
            miq_templates << @handle.root['vm']
          end

          miq_templates.each do |template|
            servicenow_sysid = template.custom_get(:servicenow_miq_template_sysid)
            if servicenow_sysid
              call_servicenow(template, servicenow_sysid)
            end
            set_custom_attributes(template)
          end

          if @handle.root['service_template_provision_task']
            @handle.root['service_template_provision_task'].destination.remove_from_vmdb
          end
          
          exit MIQ_OK
        end
        
        def get_table_name(template)
          # check template for an existing table
          template.custom_get(:servicenow_miq_template_tablename) ||
            @handle..object['table_name']
        end

        def set_custom_attributes(template)
          template.custom_set(:servicenow_miq_template_update, nil)
          template.custom_set(:servicenow_miq_template_tablename, nil)
          template.custom_set(:servicenow_miq_template_sysid, nil)
        end
        
        def call_servicenow(template, servicenow_sysid)
          @handle.instantiate("/Integration/RestClients/ServiceNow?method=delete&table_name=#{get_table_name(template)}&sysid=#{servicenow_sysid}")
        end
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
	Integration::ServiceNow::StateMachines::DeleteMIQTemplates.new.main
end
