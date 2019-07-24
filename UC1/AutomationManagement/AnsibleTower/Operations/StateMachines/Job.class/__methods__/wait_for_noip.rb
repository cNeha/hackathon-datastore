#
# Description: Wait for the IP address to be available on the VM
# For VMWare for this to work the VMWare tools should be installed
# on the newly provisioned vm's
 
module ManageIQ
  module Automate
    module AutomationManagement
      module AnsibleTower
        module Operations
          module StateMachines
            module Job
              class WaitForIP
                def initialize(handle = $evm)
                  @handle = handle
                end 
                def main
                  # Gutted everything to just exit out because we don't have an IP yet
                  $evm.log(:info, "BHP: wait_for_noip called, skipping wait_for_ip")
                  exit MIQ_OK
                end
              end
            end
          end
        end
      end
    end
  end
end
if __FILE__ == $PROGRAM_NAME
  ManageIQ::Automate::AutomationManagement::AnsibleTower::Operations::StateMachines::Job::WaitForIP.new.main
end
