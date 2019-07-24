module Integration
  module Turbonomic
    module StateMachines
      class ActionCandidates
        def initialize(handle = $evm)
          @handle = handle
          @vo = @handle.instantiate("/General/GenericObjects/ValueDictionary")
          @turbonomic_vo = @handle.instantiate("/Integration/Turbonomic/GenericObjects/ValueDictionary")
        end

        def main
          exit MIQ_OK unless @turbonomic_vo['enabled']
          
          @handle.log(:info, "===Turbonomic: Starting ActionCandidates")
          reset_vms
          reset_storages
          reset_networks
          reset_physicalmachines
          reset_diskarrays
          marketId = get_market_id
          tag_actions(marketId)
          rebuild_widgets
        end
        
        def rebuild_widgets
          @handle.log(:info, "===Turbonomic: rebuild_widget: Rebuilding Widgets")
          cmd = "/var/www/miq/vmdb/bin/rails r 'MiqWidget.find_by_title(\"Turbonomic Migration Candidates\").queue_generate_content'"
          system(cmd)
          cmd = "/var/www/miq/vmdb/bin/rails r 'MiqWidget.find_by_title(\"Turbonomic Actions\").queue_generate_content'"
          system(cmd)
          $evm.log(:info, "===Turbonomic: rebuild_widget: Rebuilt Widgets")
        end

        def chomp_name(vm_name)
          @handle.log(:info, "===Turbonomic: Chomping name from #{vm_name}")
          vm_name = vm_name[0..vm_name.rindex('_')-1]
          vm_name = vm_name[0..vm_name.rindex('_')-1]
          @handle.log(:info, "===Turbonomic: Chomping name to #{vm_name}")
          vm_name
        end

        def reset_vms
          @handle.log(:info, "===Turbonomic: Resetting VMs")
          begin
            uri = "api/vms?expand=custom_attributes&attributes=custom_attributes.name"
            client = @handle.instantiate("/Integration/RestClients/CloudFormsAPI?method=GET&uri=#{uri}&turbonomic_filter=true")
          rescue
            @handle.log(:error, "===Turbonomic: API to CloudForms failed. Exiting")
            exit MIQ_OK
          end
  
          begin
          vms = JSON.parse(client['result'])
            if vms['subcount'] > 0
              vms['resources'].each do |resource|
                $evm.log(:info, "resource result: #{resource['href']}")
                id = resource['href'][resource['href'].rindex('/')+1..-1]
                vm = @handle.vmdb('vm').find_by_id(id)
                reset_tags(vm) unless vm.nil?
              end
            end
          rescue
            @handle.log(:error, "===Turbonomic: Failure to parse CloudForms response. Exiting")
            exit MIQ_OK
          end
        end

        def reset_storages
          @handle.log(:info, "===Turbonomic: Resetting Storages")
        end

        def reset_networks
          @handle.log(:info, "===Turbonomic: Resetting Networks")
        end

        def reset_physicalmachines
          @handle.log(:info, "===Turbonomic: Resetting PhysicalMachines")
        end

        def reset_diskarrays
          @handle.log(:info, "===Turbonomic: Resetting DiskArrays")
        end

        def reset_tags(element)
          @handle.log(:info, "===Turbonomic: Resetting Tags for element #{element}")
          add_attribute(element, "turbonomic_current_host")
          add_attribute(element, "turbonomic_destination_host")
          add_attribute(element, "turbonomic_reason")
          add_attribute(element, "turbonomic_risk")
          add_attribute(element, "turbonomic_actionId")
          add_attribute(element, "turbonomic_actionType")
        end

        def add_attribute(element, key, value=nil)
          @handle.log(:info, "===Turbonomic: Adding Attribute for element #{element}, Key: #{key}, Value: #{value}")
          element.custom_set(key, value)
        end

        def tag_virtual_machine(actionItem)
          @handle.log(:info, "===Turbonomic: Tagging a VirtualMachine #{actionItem.inspect}")
          vm = @handle.vmdb("vm").find_by_name(actionItem['target']['displayName'])
          @handle.log(:info, "===Turbonomic: VM Name: #{actionItem['target']['displayName']}")
          #vm_name = chomp_name(actionItem['target']['displayName']) if vm.nil?
          #vm = @handle.vmdb("vm").find_by_name(vm_name) if vm.nil?
          unless vm.nil?
            @handle.log(:info, "===Turbonomic: Found VM Name: #{actionItem['target']['displayName']}")
            if @turbonomic_vo['auto_migrate_vm'] and actionItem['actionType'].downcase == "move"
              @handle.instantiate("/Integration/Turbonomic/StateMachines/MigrateVM?vm_name=#{vm.name}&new_host=#{actionItem['newEntity']['displayName']}")
            else
              add_attribute(vm, "turbonomic_current_host", actionItem['currentEntity']['displayName']) rescue add_attribute(vm, "turbonomic_current_host", "Undefined")
              add_attribute(vm, "turbonomic_destination_host", actionItem['newEntity']['displayName']) rescue add_attribute(vm, "turbonomic_destination_host", "Undefined")
              add_attribute(vm, "turbonomic_reason", actionItem['details']) rescue add_attribute(vm, "turbonomic_reason", "Undefined")
              add_attribute(vm, "turbonomic_risk", actionItem['risk']['severity'].downcase) rescue add_attribute(vm, "turbonomic_risk", "Undefined")
              add_attribute(vm, "turbonomic_actionId", actionItem['actionID']) rescue add_attribute(vm, "turbonomic_actionId", "")
              add_attribute(vm, "turbonomic_actionType", actionItem['actionType'].downcase) rescue add_attribute(vm, "turbonomic_actionType", "Undefined")
            end
          end
        end

        def tag_storage(actionItem)
          @handle.log(:info, "===Turbonomic: Tagging a Storage #{actionItem.inspect}")
        end

        def tag_network(actionItem)
          @handle.log(:info, "===Turbonomic: Tagging a Network #{actionItem.inspect}")
        end

        def tag_physicalmachine(actionItem)
          @handle.log(:info, "===Turbonomic: Tagging a PhyscialMachine #{actionItem.inspect}")
        end

        def tag_diskarray(actionItem)
          @handle.log(:info, "===Turbonomic: Tagging a DiskArray #{actionItem.inspect}")
        end

        def get_market_id
          @handle.log(:info, "===Turbonomic: GETting market id")
          marketId = ""
          begin
        	client = @handle.instantiate("/Integration/Turbonomic/API_V2/GET_Markets")
          rescue
            @handle.log(:error, "===Turbonomic: Failure to get_markets response. Exiting")
            exit MIQ_OK
          end
  
          begin
            markets = JSON.parse(client['result'])
            markets.each do |market|
              if market['state'].downcase == "running"
                marketId = market['uuid']
              end
            end
          rescue
            @handle.log(:error, "===Turbonomic: Failure to parse get_markets")
            exit MIQ_OK
          end
          if !marketId.empty?
          	@handle.log(:info, "===Turbonomic: Found MarketId: #{marketId}")
          else
          	@handle.log(:error, "===Turbonomic: Could Not Find MarketId. Exiting")
            exit MIQ_EXIT
          end
          marketId
        end

        def tag_actions(marketId)
          @handle.log(:info, "===Turbonomic: Tagging Actions with marketId: #{marketId}")
          begin
          	client = @handle.instantiate("/Integration/Turbonomic/API_V2/GET_MarketsActions?uuid=#{marketId}")
          rescue
            @handle.log(:error, "===Turbonomic: Failure to GET_MarketsActions call. Exiting")
            exit MIQ_OK
          end
  
          begin
            actions = JSON.parse(client['result'])
            @handle.log(:info, "===Turbonomic: result: #{client['result']}")
            actions.each do |actionItem|
              case actionItem['target']['className'].downcase
                when 'virtualmachine'
                    tag_virtual_machine(actionItem)
                when 'storage'
                    tag_storage(actionItem)
                when 'network'
                    tag_network(actionItem)
                when 'physicalmachine'
                    tag_physicalmachine(actionItem)
                when 'diskarray'
                    tag_diskarray(actionItem)
              end
            end
          rescue
            @handle.log(:error, "===Turbonomic: Failure to parse markets actions response. Exiting")
            exit MIQ_OK
          end
        end
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
	Integration::Turbonomic::StateMachines::ActionCandidates.new.main
end
