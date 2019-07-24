module Integration
  module ServiceNow
    module StateMachines
      class DeleteCMDB
        def initialize(handle = $evm)
          @handle = handle
          @vo = @handle.instantiate("/General/GenericObjects/ValueDictionary")
          @snow_vo = @handle.instantiate("/Integration/ServiceNow/GenericObjects/ValueDictionary")
        end

        def main
          exit MIQ_OK unless @snow_vo['enabled']
          
          case @handle.root['vmdb_object_type']
          when 'vm', 'miq_provision'
            task   = @handle.root['miq_provision']
            object = task.try(:destination) || @handle.root['vm']
          when 'automation_task'
            task   = @handle.root['automation_task']
            object = @handle.vmdb(:vm).find_by_name(@handle.root['vm_name']) ||
              @handle.vmdb(:vm).find_by_id(@handle.root['vm_id'])
          end

          exit MIQ_STOP unless object

          servicenow_cmdb_table = object.custom_get(:servicenow_cmdb_table)
          servicenow_cmdb_sysid = object.custom_get(:servicenow_cmdb_sysid)
          call_servicenow(servicenow_cmdb_sysid, servicenow_cmdb_table)
          clear_attributes(object)
          
          exit MIQ_OK
        end
        
        def clear_attributes(object)
          object.custom_set(:servicenow_cmdb_table, nil)
          object.custom_set(:servicenow_cmdb_sysid, nil)
        end
        
        def call_servicenow(servicenow_cmdb_sysid, servicenow_cmdb_table)
          client = @handle.instantiate("/Integration/RestClients/ServiceNow?method=#{@handle.object['method']}&table_name=#{servicenow_cmdb_table}&sysid=#{servicenow_cmdb_sysid}")
      	  @handle.object['result'] = client['result']

          @handle.log(:info, "===ServiceNow client Result: #{@handle.object['result'].inspect}")
        end
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
	Integration::ServiceNow::StateMachines::DeleteCMDB.new.main
end
