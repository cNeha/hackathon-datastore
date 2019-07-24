module Integration
  module ServiceNow
    module StateMachines
      class UpdateCMDB
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

          servicenow_cmdb_table = object.custom_get(:servicenow_cmdb_table)
          servicenow_cmdb_sysid = object.custom_get(:servicenow_cmdb_sysid)
          raise "missing servicenow_cmdb_sysid" if servicenow_cmdb_sysid.nil?


          payload = build_payload(object)

          unless payload.nil?
            if task
              payload[:short_description] = "#{object.name} - CMDB record updated via provision request #{task.miq_request.id}"
            else
              unless @handle.root['dialog_miq_alert_description'].nil?
                payload[:short_description] = "#{object.name} - CMDB record manually updated - #{@handle.root['dialog_miq_alert_description']}"
              else
                payload[:short_description] = "#{object.name} - CMDB record manually updated"
              end
            end
            payload[:comments] = get_comments(object)

            # call servicenow
            client = @handle.instantiate("/Integration/RestClients/ServiceNow?method=#{$evm.object['method']}&table_name=#{servicenow_cmdb_table}&sysid=#{servicenow_cmdb_sysid}&payload=#{payload.to_json}")
          	@handle.object['result'] = JSON.parse(client['result'])

            object.custom_set(:servicenow_cmdb_table, get_tablename(object))
            object.custom_set(:servicenow_cmdb_sysid, @handle.object['result']['sys_id'].to_s)
          
          exit MIQ_OK
        end
        
        def get_tablename(object)
          os = get_operatingsystem(object).downcase
          if os.include?('windows')
            table_name    = 'cmdb_ci_win_server'
          elsif os.include?('linux') || os.include?('unknown')
            table_name    = 'cmdb_ci_linux_server'
          elsif os.include?('rhel')
            table_name    = 'cmdb_ci_linux_server'
          else
            table_name    = 'cmdb_ci_server'
          end
          return table_name
        end

        def get_serialnumber(object)
          serial_number = nil
          case object.vendor
          when 'vmware'
            # converts vmware bios (i.e. "4231c89f-0b98-41c8-3f92-a11576c13db5") to a proper serial number
            # "VMware-42 31 c8 9f 0b 98 41 c8-3f 92 a1 15 76 c1 3d b5"
            bios = (object.hardware.bios rescue nil)
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
          comments = "Updated: #{Time.now.utc.strftime('%Y-%m-%d %H:%M:%S UTC')}\n"
          comments +=  "Vendor: #{object.vendor}\n"
          comments += "CloudForms: #{@handle.root['miq_server'].name}\n"
          comments += "Tags: #{object.tags.inspect}\n"
        end

        def build_payload(object, payload = {})
          payload = {
            :virtual            => true,
            :name               => object.name,
            :cpu_count          => object.num_cpu,
            :ram                => object.mem_cpu,
            :host_name          => get_hostname(object),
            :serial_number      => get_serialnumber(object),
            :os                 => get_operatingsystem(object),
            :os_version         => get_operatingsystem(object),
            :disk_space         => get_diskspace(object),
            :ip_address         => get_ipaddress(object),
            :cpu_core_count     => (object.hardware.cpu_total_cores rescue nil),
            :vendor             => object.vendor
          }
          return payload.compact
        end
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
	Integration::ServiceNow::StateMachines::UpdateCMDB.new.main
end
