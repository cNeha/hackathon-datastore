module Integration
  module ServiceNow
    module StateMachines
      class SyncMiqTemplates
        def initialize(handle = $evm)
          @handle = handle
          @vo = @handle.instantiate("/General/GenericObjects/ValueDictionary")
          @snow_vo = @handle.instantiate("/Integration/ServiceNow/GenericObjects/ValueDictionary")
        end

        def main
          exit MIQ_OK unless @snow_vo['enabled']
          
          delete_templates
          miq_templates = []

          if @handle.root['service_template_provision_task'] || @handle.root['service']
            miq_template_id = @handle.root['dialog_miq_template_id']
            unless miq_template_id.blank?
              miq_templates << @handle.vmdb(:miq_template).find_by_id(miq_template_id)
            else
              miq_templates = @handle.vmdb(:miq_template).all.select {|st| template_eligible?(st) }
            end
          elsif !@handle.root['vm'].nil?
            miq_templates << @handle.root['vm']
          else
           miq_templates = @handle.vmdb(:miq_template).all.select {|t| template_eligible?(t) }
          end
          raise "no miq_templates found: #{miq_templates.inspect}" if miq_templates.blank?

          miq_templates.each do |template|
            next unless template_eligible?(template)
            begin
              payload = build_payload(template)
              servicenow_sysid = template.custom_get(:servicenow_cmdb_sysid)
              if servicenow_sysid
                client = @handle.instantiate("/Integration/RestClients/ServiceNow?method=patch&table_name=#{get_table_name}&sys_id=#{servicenow_sysid}&payload=#{payload.to_json}") rescue next
                @handle.object['result'] = JSON.parse(client['result'])
              else
                client = @handle.instantiate("/Integration/RestClients/ServiceNow?method=post&table_name=#{get_table_name}&payload=#{payload.to_json}") rescue next
                @handle.object['result'] = JSON.parse(client['result'])
              end
              set_custom_attributes(template, @handle.object['result'])
            rescue
            end
          end
          exit MIQ_OK
        end
        
        def delete_templates
          client = @handle.instantiate("/Integration/RestClients/ServiceNow?method=get&table_name=#{get_table_name}")
          servicenow_query = JSON.parse(client['result'])['result']
  
          servicenow_query.each do |result|
          	template = @handle.vmdb(:miq_template).find_by_id(result['u_id'])
            if template.nil? || !template_eligible?(template)
              client = @handle.instantiate("/Integration/RestClients/ServiceNow?method=delete&sys_id=#{result['sys_id']}&table_name=#{get_table_name}")
              clear_custom_attributes(template) unless template.nil?
            end
          end
        end

        def get_operatingsystem(template)
          # try to get operating system information
          template.try(:operating_system).try(:product_name) ||
            template.try(:hardware).try(:guest_os_full_name) ||
            template.try(:hardware).try(:guest_os) || 'unknown'
        end

        def get_diskspace(template)
          # calculate allocated disk storage in GB
          diskspace = template.allocated_disk_storage
          return nil if diskspace.nil?
          return diskspace / 1024**3
        end

        def get_table_name
          @handle.object['table_name']
        end

        def template_eligible?(template)
          # example to only sync templates tagged with environment
          #return false if template.tags(:environment).nil?

          # disregard archived and orphaned templates
          return false if template.archived || template.orphaned
          return true
        end

        def set_custom_attributes(obj, servicenow_result)
          now = Time.now.strftime('%Y%m%d-%H%M%S').to_s
          obj.custom_set(:servicenow_cmdb_update, now)
          obj.custom_set(:servicenow_cmdb_tablename, get_table_name)
          obj.custom_set(:servicenow_cmdb_sysid, servicenow_result['result']['sys_id'].to_s)
        end

        def clear_custom_attributes(obj)
          obj.custom_set(:servicenow_cmdb_update, nil)
          obj.custom_set(:servicenow_cmdb_tablename, nil)
          obj.custom_set(:servicenow_cmdb_sysid, nil)
        end

        def build_payload(obj, payload = {})
          payload = {
            :u_id					=> obj.id,
            :u_name					=> obj.name,
            :u_type       			=> obj.type,
            :u_ems_ref    			=> obj.ems_ref,
            :u_ems_id    			=> obj.ems_id,
            :u_ext_management_id	=> obj.try(:ext_management_system).try(:id),
            :u_provider     		=> obj.try(:ext_management_system).try(:name),
            :u_guid       			=> obj.guid,
            :u_cloud      			=> obj.cloud.to_s,
            :u_disk_space 			=> get_diskspace(obj),
            :u_guest_os   			=> get_operatingsystem(obj),
            :u_mem_cpu    			=> obj.mem_cpu.to_i,
            :u_num_cpu    			=> obj.num_cpu,
            :u_template   			=> obj.template.to_s,
            :u_uid_ems    			=> obj.uid_ems,
            :u_vendor     			=> obj.vendor
          }
          # ServiceNow does not like nil values using compact to remove them
          return payload.compact
        end
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
	Integration::ServiceNow::StateMachines::SyncMiqTemplates.new.main
end
