module Integration
  module ServiceNow
    module StateMachines
      class ResolveIncident
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

          exit MIQ_STOP unless @object

          servicenow_incident_sysid = object.custom_get(:servicenow_incident_sysid)
          raise "missing servicenow_incident_sysid" if servicenow_incident_sysid.nil?

          payload = {}
          # as per snow documentation state '6' = 'resolved'
          payload['state'] = '6'
          payload['caller_id'] = @snow_vo['caller_id']
          payload['close_code'] = 'Closed/Resolved By Caller'

          # object_name = 'Event' means that we were triggered from an Alert
          if @handle.root['object_name'] == 'Event'
            payload['close_notes'] = "#{@handle.root['vmdb_object_type']}: #{object.name} - #{@handle.root['miq_alert_description']}"
          elsif @handle.root['ems_event']
            # ems_event means that were triggered via Control Policy
            payload['close_notes'] = "#{@handle.root['vmdb_object_type']}: #{object.name} - #{@handle.root['ems_event'].event_type}"
          else
            unless @handleroot['dialog_miq_alert_description'].nil?
              payload['close_notes'] = "#{@handle.root['vmdb_object_type']}: #{object.name} - #{@handle.root['dialog_miq_alert_description']}"
            else
              payload['close_notes'] = "#{@handle.root['vmdb_object_type']}: #{object.name} - Incident manually resolved"
            end
          end

          call_servicenow(servicenow_incident_sysid, payload)
          clear_attributes(object)
          
          exit MIQ_OK
        end
        
        def get_table_name
          @handle.object['table_name']
        end
        
        def call_servicenow(servicenow_incident_sysid, payload)
          client = @handle.instantiate("/Integration/RestClients/ServiceNow?method=#{$evm.object['method']}&table_name=#{get_table_name}&sysid=#{servicenow_incident_sysid}&payload=#{payload.to_json}")
          @handle.object['result'] = JSON.parse(client['result'])
        end

        def clear_attributes(object)
          object.custom_set(:servicenow_incident_number, nil)
          object.custom_set(:servicenow_incident_sysid, nil)
          object.custom_set(:servicenow_incident_state, nil)
        end
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
	Integration::ServiceNow::StateMachines::ResolveIncident.new.main
end
