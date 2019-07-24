module Integration
  module ServiceNow
    module StateMachines
      class SyncAll
        def initialize(handle = $evm)
          @handle = handle
          @vo = @handle.instantiate("/General/GenericObjects/ValueDictionary")
          @snow_vo = @handle.instantiate("/Integration/ServiceNow/GenericObjects/ValueDictionary")
        end

        def main
          exit MIQ_OK unless @snow_vo['enabled']
          
          @handle.instantiate("/Integration/ServiceNow/StateMachines/SyncProviders")
          @handle.instantiate("/Integration/ServiceNow/StateMachines/SyncFlavors")
          @handle.instantiate("/Integration/ServiceNow/StateMachines/SyncAvailabilityZones")
          @handle.instantiate("/Integration/ServiceNow/StateMachines/SyncCloudNetworks")
          @handle.instantiate("/Integration/ServiceNow/StateMachines/SyncCloudSubnets")
          @handle.instantiate("/Integration/ServiceNow/StateMachines/SyncSecurityGroups")
          @handle.instantiate("/Integration/ServiceNow/StateMachines/SyncAuthKeyPairs")
          @handle.instantiate("/Integration/ServiceNow/StateMachines/SyncVMs")
          
          @handle.instantiate("/Integration/ServiceNow/StateMachines/SyncMiqTemplates")
          @handle.instantiate("/Integration/ServiceNow/StateMachines/SyncServiceTemplates")
          exit MIQ_OK
        end
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
	Integration::ServiceNow::StateMachines::SyncAll.new.main
end
