=begin
PUT https://devXXXX.service-now.com/api/now/table/incident/2eed78cd4f763200eacf2ed18110c143


Parameter in BOLD is sys_id of the ticket being closed



Payload - {"close_code":"Closed/Resolved By Caller","state":"7","caller_id":"6816f79cc0a8016401c5a33be04be331","close_notes":"Closed by API"}


caller_id in bold is the sys_id for the user closing the ticket.

d24dfcfcdbcf1b0004819015ca961903

These are the minimum field required to cklose.
=end

module Integration
  module ServiceNow
    module StateMachines
      class CloseIncident
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
            object = @handle.vmdb(:vm).find_by_name(@handle.root['vm_name']) ||
              @handle.vmdb(:vm).find_by_id(@handle.root['vm_id'])
          end

          exit MIQ_STOP unless object

          servicenow_incident_sysid = get_sys_id(object)
          if servicenow_incident_sysid.nil?
            exit MIQ_OK
          end

          payload = load_payload(object)
          call_servicenow(servicenow_incident_sysid, payload)
          clear_attributes(object)
          exit MIQ_OK
        end
        
        def get_sys_id(object)
          object.custom_get(:servicenow_incident_sysid)
        end
        
        def get_close_notes(payload, object)
          # object_name = 'Event' means that we were triggered from an Alert
          if @handle.root['object_name'] == 'Event'
            payload['close_notes'] = "#{@handle.root['vmdb_object_type']}: #{object.name} - #{@handle.root['miq_alert_description']}"
          elsif @handle.root['ems_event']
            # ems_event means that were triggered via Control Policy
            payload['close_notes'] = "#{@handle.root['vmdb_object_type']}: #{object.name} - #{@handle.root['ems_event'].event_type}"
          else
            unless $evm.root['dialog_miq_alert_description'].nil?
              # If manual creation add dialog input notes to payload
              payload['close_notes'] = "#{@handle.root['vmdb_object_type']}: #{object.name} - #{@handle.root['dialog_miq_alert_description']}"
            else
              # If manual creation add default notes to payload
              payload['close_notes'] = "#{@handle.root['vmdb_object_type']}: #{object.name} - Incident manually closed"
            end
          end
          payload
        end
        
        def load_payload(object, payload = {})
          # as per snow documentation state '7' = 'closed'
          payload['state'] = '7'
          payload['caller_id'] = @snow_vo['caller_id']
          payload['close_code'] = 'Closed/Resolved By Caller'
          payload = get_close_notes(payload, object)
          payload
        end
        
        def call_servicenow(servicenow_incident_sysid, payload)
          client = @handle.instantiate("/Integration/RestClients/ServiceNow?method=#{@handle.object['method']}&table_name=#{@handle.object['table_name']}&sysid=#{servicenow_incident_sysid}&payload=#{payload.to_json}")
          @handle.object['result'] = client['result']
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
	Integration::ServiceNow::StateMachines::CloseIncident.new.main
end
