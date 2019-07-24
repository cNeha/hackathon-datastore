module Integration
  module Turbonomic
    module StateMachines
      class WorkloadPlacement
        def initialize(handle = $evm)
          @handle = handle
          @vo = @handle.instantiate("/General/GenericObjects/ValueDictionary")
          @turbonomic_vo = @handle.instantiate("/Integration/ServiceNow/GenericObjects/ValueDictionary")
        end

        def main
          exit MIQ_OK unless @turbonomic_vo['enabled']
          
          @handle.log(:info, "VM ID: #{@handle.root['vm_id']}")
          vm = @handle.vmdb('vm').find_by_id(@handle.root['vm_id'])
          vm_name = vm.name
          @handle.log(:info, "VM Name: #{vm_name}")
          template = @handle.object['template']

          templateId 		= get_templateID(template)
          payload 		    = build_payload(templateId, vm_name)
          reservationId 	= get_reservation_id(payload)
          targetHost 		= get_target_host(reservationId)

          unless targetHost.empty?
            @handle.log(:info, "===Turbonomic: Calling migrate for #{vm_name} to Host: #{targetHost}") 
            @handle.instantiate("/Integration/Turbonomic/StateMachines/MigrateVM?new_host=#{targetHost}&vm_name=#{vmName}")
          end
          
          exit MIQ_OK
        end
        
        def get_templateID(template)
          templateId = ""
          @handle.log(:info, "===Turbonomic: Getting Template ID for template name: #{template}")
  
          begin
            tf = @handle.instantiate('/Integration/Turbonomic/API_V2/GET_Templates?uuid_or_type=VirtualMachine')
          rescue
            @handle.log(:error, "===Turbonomic: Failure in call to Turbonomic GET_Templates. Exiting")
            exit MIQ_OK
          end

          begin
            jsonAry = JSON.parse(tf['result'])
            jsonAry.each do |element|
              if element['displayName'].include? template
                templateId = element['uuid'].to_s
                break
              end
            end
          rescue => e
            @handle.log(:error, "===Turbonomic: Failed to parse response from GET_Templates. Exiting")
            exit MIQ_OK
          end
  
          if !templateId.empty?
            $evm.log(:info, "===Turbonomic: Found TemplateID: #{templateId}")
          else
            $evm.log(:error, "===Turbonomic: Could not find a templateId for template: #{template}. Exiting")
            exit MIQ_EXIT
          end
          templateId
        end

        def get_reservation_id(payload)
          @handle.log(:info, "===Turbonomic: POSTing reservation with payload: #{payload}")
          reservationId = ""
          begin 
            turbo_reservations = @handle.instantiate("/Integration/Turbonomic/API_V2/POST_Reservations?payload=#{payload}&action=RESERVATION")
            srcJSONParse = JSON.parse(turbo_reservations['result'])
            reservationId = srcJSONParse['uuid']
          rescue => e
            @handle.log(:error, "===Turbonomic: Failed to parse response from POST_Reservations #{turbo_reservations['result']}. Exiting")
            exit MIQ_OK
          end
          reservationId
        end

        def get_target_host(reservationId)
          @handle.log(:info, "===Turbonomic: GETting reservation with reservationId: #{reservationId}")
          targetHost = ""
          begin 
            turbo_reservations = @handle.instantiate("/Integration/Turbonomic/API_V2/GET_Reservations?uuid=#{reservationId}")
            srcJSONParse = JSON.parse(turbo_reservations['result'])
            targetHost = srcJSONParse['demandEntities'][0]['placements']['computeResources'][0]['provider']['displayName']
          rescue => e
            @handle.log(:error, "===Turbonomic: Failed to parse response from GET_Reservations: #{turbo_reservations['result']}")
            exit MIQ_OK
          end
          targetHost
        end

        def build_payload(templateId, vm_name, payload = {})
          payload = {
            :demandName => vm_name + "_" + Time.now.to_i.to_s,
            :action => "RESERVATION",
            :expireDateTime => "#{(Time.now + 10.minutes).strftime('%Y-%m-%dT%H:%M:%S+00:00')}",
            :parameters => [
              {
                :placementParameters=> {
                  :count => 1,
                  :geographicRedundancy => false,
                  :templateID => templateId
                }
              }
            ]
          }.to_json
        end
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
	Integration::Turbonomic::StateMachines::WorkloadPlacement.new.main
end
