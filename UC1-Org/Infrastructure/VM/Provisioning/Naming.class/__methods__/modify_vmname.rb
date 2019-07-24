# / Infra / VM / Provisioning / Naming / default (vmname)

#
# Description: This is the default naming scheme
# 1. If VM Name was not chosen during dialog processing then use vm_prefix
#    from dialog else use model and [:environment] tag to generate name
# 2. Else use VM name chosen in dialog
# 3. Add 3 digit suffix to vmname if more than one VM is being provisioned
#
module ManageIQ
  module Automate
    module Infrastructure
      module VM
        module Provisioning
          module Naming
            class VmName
              def initialize(handle = $evm)
                @handle = handle
              end

              def main
                @handle.log("info", "BHP: Detected vmdb_object_type:<#{@handle.root['vmdb_object_type']}>")
                @handle.object['vmname'] = derived_name.compact.join
                # This is custom VM naming stuff
                # If the options are set, then run special naming
                                
                @handle.log("info", "BHP: the object description--->(#{provision_object.get_option(:description)})<---")
                if @handle.root['vmdb_object_type'] == "miq_provision" && !provision_object.get_option(:description).nil? && !provision_object.get_option(:description).include?("deployment")
                  @handle.log("info", "BHP: Entering special naming section")
                  @handle.object['vmname'] = create_vm_name
                end
                # End of custom VM naming stuff
                @handle.log(:info, "BHP: vmname: \"#{@handle.object['vmname']}\"")
              end

              def create_vm_name
                # This is custom VM naming stuff
                request_object = provision_object.miq_request
                platform = request_object.options[:dialog]['dialog_option_0_os']
                environ = request_object.options[:dialog]['dialog_option_0_environment']
                zone = request_object.options[:dialog]['dialog_tag_0_security_zone']
                dc = request_object.options[:dialog]['dialog_option_0_data_centre']
                packages = request_object.options[:dialog]['Array::dialog_option_0_packages']
                if !packages.present?
                  packages = request_object.options[:dialog]['dialog_option_0_job_template_name']
                end
                oname = platform[0]
                app_code = packages[0..1].gsub(/[^0-9a-z]/i, '')
                env = environ[0..1].gsub(/[^0-9a-z]/i, '')
                return "syd#{dc}#{oname}#{app_code}#{env}"
              end
              
              def derived_name
                if supplied_name.present?
                  [supplied_name, suffix(true)]
                else
                  [prefix, env_tag, suffix(false)]
                end
              end

              def supplied_name
                @supplied_name ||= begin
                  vm_name = provision_object.get_option(:vm_name).to_s.strip
                  vm_name unless vm_name == 'changeme'
                  @handle.log("info", "BHP: vm_name:<#{vm_name}>")
                end
              end

              def provision_object
                @provision_object ||= begin
                  @handle.root['miq_provision_request'] ||
                  @handle.root['miq_provision']         ||
                  @handle.root['miq_provision_request_template']
                end
              end

              # Returns the name prefix (preferences model over dialog) or nil
              def prefix
                @handle.object['vm_prefix'] || provision_object.get_option(:vm_prefix).to_s.strip
              end

              # Returns the first 3 characters of the "environment" tag (or nil)
              def env_tag
                env = provision_object.get_tags[:environment]
                return env[0, 3] unless env.blank?
              end

              # Returns the name suffix (provision number) or nil if provisioning only one
              def suffix(condensed)
                "$n{3}" if provision_object.get_option(:number_of_vms) > 1 || !condensed
              end
            end
          end
        end
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  ManageIQ::Automate::Infrastructure::VM::Provisioning::Naming::VmName.new.main
end
