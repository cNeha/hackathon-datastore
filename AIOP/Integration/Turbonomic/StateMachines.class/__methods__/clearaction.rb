module Integration
  module Turbonomic
    module StateMachines
      class ClearAction
        def initialize(handle = $evm)
          @handle = handle
          @vo = @handle.instantiate("/General/GenericObjects/ValueDictionary")
          @turbonomic_vo = @handle.instantiate("/Integration/Turbonomic/GenericObjects/ValueDictionary")
        end

        def main
          exit MIQ_OK unless @turbonomic_vo['enabled']
          
          @handle.log(:info, "===Turbonomic: Starting ClearAction")
          
          vm_id = @handle.parent['vm_id'].nil? ? @handle.object['vm_id'] : @handle.parent['vm_id']
          vm = @handle.vmdb("vm").find_by_id(vm_id)
          clear_attributes(vm)
        end
        
        def clear_attributes(vm = nil)
          unless vm.nil?
            vm.custom_set("turbonomic_current_host", nil)
            vm.custom_set("turbonomic_destination_host", nil) 
            vm.custom_set("turbonomic_reason", nil)
            vm.custom_set("turbonomic_actionType", nil)
            vm.custom_set("turbonomic_risk", nil)
            vm.custom_set("turbonomic_actionID", nil)
          end
        end
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
	Integration::Turbonomic::StateMachines::ClearAction.new.main
end
