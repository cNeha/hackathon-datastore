module Integration
  module Turbonomic
    module StateMachines
      class MigrateVM
        def initialize(handle = $evm)
          @handle = handle
          @vo = @handle.instantiate("/General/GenericObjects/ValueDictionary")
          @turbonomic_vo = @handle.instantiate("/Integration/Turbonomic/GenericObjects/ValueDictionary")
        end

        def main
          exit MIQ_OK unless @turbonomic_vo['enabled']
          
          @handle.log(:info, "===Turbonomic: Starting MigrateVM")
          vm_name = @handle.parent['vm_name'].nil? ? @handle.object['vm_name'] : @handle.parent['vm_name']
          new_host = @handle.parent['new_host'].nil? ? @handle.object['new_host'] : @handle.parent['new_host']

          vm = @handle.vmdb("vm").find_by_name(vm_name)
          if vm.nil?
            @handle.log(:error, "===Turbonomic: Failed Migrating VM: #{vm_name} since it was not found. Exiting")
            exit MIQ_OK
          end
          
          if !new_host.include? vm.host.hypervisor_hostname
            process_hosts(vm, new_host)
          end
        end
        
        def process_hosts(vm, new_host)
          is_found = false
          target_host = vm.host
          ems_hosts = vm.ems_cluster.hosts
  
          ems_hosts.each do |host|
            if new_host.include? host.hypervisor_hostname and is_found == false
              target_host = host
              is_found = true
              break
            end
          end
  
          if is_found == true
            @handle.log(:info, "===Turbonomic: Migrating VM id: #{vm.id} to Hostname: #{new_host}")
            cmd = "/var/www/miq/vmdb/bin/rails r 'ManageIQ::Providers::Openstack::CloudManager::Vm.live_migrate(#{vm.id}, {:hostname=> \"#{new_host}\"})'"
            system(cmd)
            @handle.instantiate("/Integration/Turbonomic/StateMachines/ClearAction?new_id=#{vm.id}")
          else
            @handle.log(:error, "===Turbonomic: Failed Migrating VM: #{vm.id} to Hostname: #{new_host} since host was not found. Exiting")
          end
        end
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
	Integration::Turbonomic::StateMachines::MigrateVM.new.main
end
