module Integration
  module ServiceNow
    module StateMachines
      class CreateIncident
        def initialize(handle = $evm)
          @handle = handle
          @vo = @handle.instantiate("/General/GenericObjects/ValueDictionary")
          @snow_vo = @handle.instantiate("/Integration/ServiceNow/GenericObjects/ValueDictionary")
        end

        def main
          exit MIQ_OK unless @snow_vo['enabled']
          
          case $evm.root['vmdb_object_type']
          when 'vm', 'miq_provision'
            task   = @handle.root['miq_provision']
            object = task.try(:destination) || @handle.root['vm']
          when 'automation_task'
            task   = @handle.root['automation_task']
            object = @handle.vmdb(:vm).find_by_name(@handle.root['vm_name']) || @handle.vmdb(:vm).find_by_id(@handle.root['vm_id'])
          end

          exit MIQ_STOP unless object
          payload = build_incident_body(object)
          payload['caller_id'] = @snow_vo['caller_id']
          payload['contact_type'] = 'self-service'
          payload['impact'] = @handle.root['dialog_impact'] rescue 3
          payload['urgency'] = @handle.root['dialog_urgency'] rescue 3
          
          if @handle.root['object_name'] == 'Event'
            payload['short_description'] = "#{@handle.root['vmdb_object_type']}: #{object.name} - #{@handle.root['miq_alert_description']}"
          elsif @handle.root['ems_event']
            # ems_event means that were triggered via Control Policy
            payload['short_description'] = "#{@handle.root['vmdb_object_type']}: #{object.name} - #{@handle.root['ems_event'].event_type}"
          else
            unless @handle.root['dialog_miq_alert_description'].nil?
              # If manual creation add dialog input notes to body_hash
              payload['short_description'] = "#{@handle.root['vmdb_object_type']}: #{object.name} - #{@handle.root['dialog_miq_alert_description']}"
            else
              payload['short_description'] = "#{@handle.root['vmdb_object_type']}: #{object.name} - Incident manually created"
            end
            
            call_servicenow(payload)
            set_attributes(object)
          end
          exit MIQ_OK
        end
        
        def set_attributes(object)
          object.custom_set(:servicenow_incident_number, @handle.object['result']['number'].to_s)
          object.custom_set(:servicenow_incident_sysid, @handle.object['result']['sys_id'].to_s)
          object.custom_set(:servicenow_incident_state, @handle.object['result']['state'].to_s)
        end
        
        def call_servicenow(payload)
          client = $evm.instantiate("/Integration/RestClients/ServiceNow?method=#{@handle.object['method']}&table_name=#{@handle.object['table_name']}&payload=#{payload.to_json}")
      	  @handle.object['result'] = JSON.parse(client['result'])

          @handle.log(:info, "---ServiceNow client Result: #{@handle.object['result'].inspect}")
        end
        
        def get_hostname(object)
          hostname = object.hostnames.first rescue nil
          hostname.blank? ? (return object.name) : (return hostname)
        end

        def get_ipaddress(object)
          ip = object.ipaddresses
          ip.blank? ? (return object.hardware.ipaddresses || nil) : (return ip)
        end

        def get_operatingsystem(object)
          object.try(:operating_system).try(:product_name) ||
            object.try(:hardware).try(:guest_os_full_name) ||
            object.try(:hardware).try(:guest_os) || 'unknown'
        end

        def get_diskspace(object)
          diskspace = object.allocated_disk_storage
          return nil if diskspace.nil?
          return diskspace / 1024**3
        end

        def build_incident_body(object)
          comments  = "VM: #{object.name}\n"
          comments += "Hostname: #{get_hostname(object)}\n"
          comments += "Guest OS Description: #{get_operatingsystem(object)}\n"
          comments += "IP Address: #{get_ipaddress(object)}\n"
          comments += "Provider: #{object.ext_management_system.name}\n" unless object.ext_management_system.nil?
          comments += "Cluster: #{object.try(:ems_cluster).try(:name)}\n" unless object.ems_cluster.nil?
          comments += "Host: #{object.try(:host).try(:name)}\n" unless object.host.nil?
          comments += "CloudForms Server: #{@handle.root['miq_server'].hostname}\n"
          comments += "Region Number: #{object.region_number}\n"
          comments += "vCPU: #{object.num_cpu}\n"
          comments += "vRAM: #{object.mem_cpu}\n"
          comments += "Disks: #{object.num_disks}\n"
          comments += "Power State: #{object.power_state}\n"
          comments += "Storage Name: #{object.try(:storage_name)}\n" unless object.storage_name.nil?
          comments += "Allocated Storage: #{get_diskspace(object)}\n"
          comments += "GUID: #{object.guid}\n"
          comments += "Tags: #{object.tags.inspect}\n"
          (body_hash ||= {})['comments'] = comments
          return body_hash
        end
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
	Integration::ServiceNow::StateMachines::CreateIncident.new.main
end
