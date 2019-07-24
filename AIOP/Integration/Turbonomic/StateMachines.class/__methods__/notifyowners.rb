module Integration
  module Turbonomic
    module StateMachines
      class NotifyOwners
        def initialize(handle = $evm)
          @handle = handle
          @vo = @handle.instantiate("/General/GenericObjects/ValueDictionary")
          @turbonomic_vo = @handle.instantiate("/Integration/Turbonomic/GenericObjects/ValueDictionary")
        end

        def main
          exit MIQ_OK unless @turbonomic_vo['enabled']
          
          @handle.log(:info, "===Turbonomic: Starting NotifyOwners")
          from_email_address = @vo['default_from_email_address']
          default_to_email_address = @vo['default_to_email_address']
          
          if @turbonomic_vo['send_action_emails']
            notifications = {}

            vms = get_tagged_vms
            vms.each do |vm|
              #check if vm has an actionType
              unless vm.custom_get("turbonomic_actionType").nil?
                to_email_address = (vm.owner.nil? or vm.owner.email.empty?) ? default_to_email_address : vm.owner.email
                notifications = build_notification_setup(vm, to_email_address, notifications)
                notifications = build_move_notifications(vm, to_email_address, notifications) if vm.custom_get("turbonomic_actionType").downcase == "move"
                notifications = build_suspend_notifications(vm, to_email_address, notifications) if vm.custom_get("turbonomic_actionType").downcase == "suspend"
                notifications = build_right_size_notifications(vm, to_email_address, notifications) if vm.custom_get("turbonomic_actionType").downcase == "right_size"
              end  
            end

            send_email(notifications, from_email_address)
          end
          
          def get_tagged_vms
            @handle.log(:info, "===Turbonomic: Getting Tagged VMs")
            found_vms = []
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
                  @handle.log(:info, "resource result: #{resource['href']}")
                  id = resource['href'][resource['href'].rindex('/')+1..-1]
                  found_vms << @handle.vmdb('vm').find_by_id(id)
                end
              end
            rescue
              @handle.log(:error, "===Turbonomic: Failure to parse CloudForms response. Exiting")
              exit MIQ_OK
  			end
            found_vms
          end
          
          def send_email(notifications, from_email_address)
            subject = "Turbonomic Recommendations"
            notifications.each do |key, value|
              to_email = key
              body = ""
          	value.each do |k,v|
          	  v.each do |message|
          	    body += message
          	  end
              end
            @handle.log(:info, "===Turbonomic Sending email to <#{to_email}> from: <#{from_email_address}> subject: <#{subject}> body: #{body}")
            @handle.execute(:send_email, to_email, from_email_address, subject, body)
            end
          end

          def build_notification_setup(vm, to_email_address, notifications)
            actionType = vm.custom_get("turbonomic_actionType")
            notifications[to_email_address] ||= {}
            notifications[to_email_address][actionType] ||= []
            notifications
          end

          def build_move_notifications(vm, to_email_address, notifications)
            old_host 	= vm.custom_get("turbonomic_current_host")
            new_host 	= vm.custom_get("turbonomic_destination_host")
            reason 	= vm.custom_get("turbonomic_reason")
            body 		= "VM Name: #{vm.name} is a candidate for migration from: #{old_host} to: #{new_host} for this reason: #{reason}\n"
            actionType = vm.custom_get("turbonomic_actionType")
            notifications[to_email_address][actionType] << body
            notifications
          end

          def build_suspend_notifications(vm, to_email_address, notifications)
            old_host 	= vm.custom_get("turbonomic_current_host")
            reason 	= vm.custom_get("turbonomic_reason")
            body 		= "VM Name: #{vm.name} is a candidate for suspension on #{old_host} for this reason: #{reason}\n"
            actionType = vm.custom_get("turbonomic_actionType")
            notifications[to_email_address][actionType] << body
            notifications
          end

          def build_right_size_notifications(vm, to_email_address, notifications)
            old_host 	= vm.custom_get("turbonomic_current_host")
            reason 	= vm.custom_get("turbonomic_reason")
            body 		= "VM Name: #{vm.name} is a candidate for right sizing for this reason: #{reason}\n"
            actionType = vm.custom_get("turbonomic_actionType")
            notifications[to_email_address][actionType] << body
            notifications
          end
        end
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
	Integration::Turbonomic::StateMachines::NotifyOwners.new.main
end
