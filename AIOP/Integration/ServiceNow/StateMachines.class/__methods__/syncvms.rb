module Integration
  module ServiceNow
    module StateMachines
      class SyncVMs
        def initialize(handle = $evm)
          @handle = handle
          @vo = @handle.instantiate("/General/GenericObjects/ValueDictionary")
          @snow_vo = @handle.instantiate("/Integration/ServiceNow/GenericObjects/ValueDictionary")
        end

        def main
          exit MIQ_OK unless @snow_vo['enabled']
          
          delete_vms
          vms = []
          
          case $evm.root['vmdb_object_type']
          when 'vm', 'miq_provision'
            task   = @handle.root['miq_provision']
            vms << task.try(:destination) || @handle.root['vm']
          when 'automation_task'
            task   = @handle.root['automation_task']
            vms << @handle.vmdb(:vm).find_by_name(@handle.root['vm_name']) ||
            @handle.vmdb(:vm).find_by_id($evm.root['vm_id'])
          end
          
          if vms.empty?
            vms = @handle.vmdb(:vm).all.select {|vm| vm_eligible?(vm) }
          end

          vms.each do |vm|
            payload = build_payload(vm)

            if task
              payload[:short_description] = "#{vm.name} - CMDB record created via provision request #{task.miq_request.id}"
            else
              unless $evm.root['dialog_miq_alert_description'].nil?
                payload[:short_description] = "#{vm.name} - #{$evm.root['dialog_miq_alert_description']}"
              else
                payload[:short_description] = "#{vm.name} - CMDB record manually created"
              end
            end
    
            payload[:comments] = get_comments(vm)
            servicenow_sysid = vm.custom_get(:servicenow_cmdb_sysid)

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
            
            set_custom_attributes(vm, @handle.object['result'])
          end
          exit MIQ_OK
        end
        
        def set_custom_attributes(object, servicenow_result)
          object.custom_set(:servicenow_cmdb_table, get_table_name)
          object.custom_set(:servicenow_cmdb_sysid, servicenow_result['result']['sys_id'].to_s)
        end
        
        def clear_custom_attributes(object)
          object.custom_set(:servicenow_cmdb_table, nil)
          object.custom_set(:servicenow_cmdb_sysid, nil)
        end
        
        def call_servicenow(payload)
          client = @handle.instantiate("/Integration/RestClients/ServiceNow?method=#{@handle.object['method']}&table_name=#{get_table_name}&payload=#{payload.to_json}")
      	  @handle.object['result'] = JSON.parse(client['result'])

          @handle.log(:info, "---ServiceNow client Result: #{@handle.object['result'].inspect}")
        end
        
        def delete_vms
          client = @handle.instantiate("/Integration/RestClients/ServiceNow?method=get&table_name=#{get_table_name}")
          servicenow_query = JSON.parse(client['result'])['result']
  
          servicenow_query.each do |result|
          	vm = @handle.vmdb(:vm).find_by_id(result['u_id'])
            if vm.nil? || !vm_eligible?(vm)
              client = @handle.instantiate("/Integration/RestClients/ServiceNow?method=delete&sys_id=#{result['sys_id']}&table_name=#{get_table_name}")
              clear_custom_attributes(vm) unless vm.nil?
            end
          end
        end

        def vm_eligible?(vm)
          return false if vm.archived || vm.orphaned
          return true
        end
        
        def get_table_name
          @handle.object['table_name']
        end

        def get_serialnumber(object)
          serial_number = nil
          case object.vendor
          when 'vmware'
            # converts vmware bios (i.e. "4231c89f-0b98-41c8-3f92-a11576c13db5") to a proper serial number
            # "VMware-42 31 c8 9f 0b 98 41 c8-3f 92 a1 15 76 c1 3d b5"
            bios = (@object.hardware.bios rescue nil)
            return nil if bios.nil?
            bios1 = bios[0, 18].gsub(/-/, '').scan(/\w\w/).join(" ")
            bios2 = bios[19, bios.length].gsub(/-/, '').scan(/\w\w/).join(" ")
            serial_number = "VMware-#{bios1}-#{bios2}"
          end
          return serial_number
        end

        def get_operatingsystem(object)
          object.try(:operating_system).try(:product_name) ||
            object.try(:hardware).try(:guest_os_full_name) ||
            object.try(:hardware).try(:guest_os) || 'unknown'
        end

        def get_hostname(object)
          hostname = object.hostnames.first rescue nil
          hostname.blank? ? (return object.name) : (return hostname)
        end

        def get_diskspace(object)
          diskspace = object.allocated_disk_storage
          return nil if diskspace.nil?
          return diskspace / 1024**3
        end

        def get_ipaddress(object)
          ip = object.ipaddresses.first
          ip.blank? ? (return object.hardware.ipaddresses.first || nil) : (return ip)
        end

        def get_comments(object)
          comments =  "Vendor: #{object.vendor}\n"
          comments += "CloudForms: #{@handle.root['miq_server'].name}\n"
          comments += "Tags: #{object.tags.inspect}\n"
          comments
        end

        def build_payload(obj, payload = {})
          payload = {
            :u_virtual            	=> true,
            :u_id               	=> obj.id,
            :u_name               	=> obj.name,
            :u_ext_management_id    => obj.try(:ext_management_system).try(:id),
            :u_ems_id				=> obj.ems_id,
            :u_ems_ref				=> obj.ems_ref,
            :u_cpu_count          	=> obj.num_cpu,
            :u_ram                	=> obj.mem_cpu,
            :u_hostname          	=> get_hostname(obj),
            :u_serial_number      	=> get_serialnumber(obj),
            :u_os                 	=> get_operatingsystem(obj),
            :u_os_version         	=> get_operatingsystem(obj),
            :u_disk_space         	=> get_diskspace(obj),
            :u_ip_address         	=> get_ipaddress(obj),
            :u_cpu_core_count     	=> (obj.hardware.cpu_total_cores rescue nil),
            :u_vendor             	=> obj.vendor
          }
          # ServiceNow does not like nil values using compact to remove them
          return payload.compact
        end
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
	Integration::ServiceNow::StateMachines::SyncVMs.new.main
end
