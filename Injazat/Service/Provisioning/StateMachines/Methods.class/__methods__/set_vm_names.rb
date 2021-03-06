# This function takes care of naming a set of VMs with all unique names.
# This function also ensures that there is no other service trying to name VMs
# with the same prefix at the same time to avoid VM name duplication.
#
# EXPECTED
#   EVM ROOT
#     service_template_provision_task - service task to set the VM names for
#       required options:
#         dialog
#           dialog_vm_prefix - VM name prefix to use when naming VMs.
#
# @see https://pemcg.gitbooks.io/mastering-automation-in-cloudforms-4-2-and-manage/content/the_service_provisioning_state_machine/chapter.html#_vm_naming_for_services
# @see https://pemcg.gitbooks.io/mastering-automation-in-cloudforms-4-2-and-manage/content/service_objects/chapter.html
#
@DEBUG = true

RETRY_INTERVAL                = 10
DEFAULT_SUFFIX_COUNTER_LENGTH = 3

# Log an error and exit.
#
# @param msg Message to error with
def error(msg)
  $evm.log(:error, msg)
  $evm.root['ae_result'] = 'error'
  $evm.root['ae_reason'] = msg.to_s
  exit MIQ_STOP
end


#$evm = MiqAeMethodService::MiqAeService.new(MiqAeEngine::MiqAeWorkspaceRuntime.new)

def get_hypervisor(provider)
  if provider.type == "ManageIQ::Providers::Vmware::InfraManager"
    return "A"
  elsif provider.type == "ManageIQ::Providers::Openstack::CloudManager"
    return "B"
  end
end

def get_source_site(catalog_item)
  if  catalog_item.tagged_with?("catalog_role", "primary")
    return "primary"
  elsif  catalog_item.tagged_with?("catalog_role", "secondary")
    return "secondary"
  end
end

def get_region(provider)
  if provider.tagged_with?("provider_role", "primary")
    return "1"
  elsif provider.tagged_with?("provider_role", "secondary")
    return "2"
  end
end

def get_environment(environment)
  # this will be based on dropdown
  case environment
    when "Production"
      return "01"
    when "Pre-Production"
      return "02"
    when "Test"
       return "03"
    when "Development"
      return "04"
    when "Reserved"
      return "05"
  end
end

def get_site(source_site, dr_enabled, provider)

  if provider.tagged_with?("provider_role", "primary")
    current_site = "primary"
  elsif provider.tagged_with?("provider_role", "secondary")
    current_site = "secondary"
  end

  case source_site
    when "primary"
      if dr_enabled and current_site == "primary"
        return "01"
      elsif not dr_enabled and current_site == "primary"
        return "01"
      elsif dr_enabled and current_site = "secondary"
        return "02"
      end
    when "secondary"
      if dr_enabled and current_site == "primary"
        return "02"
      elsif dr_enabled and current_site = "secondary"
        return "01"
      elsif not dr_enabled and current_site = "secondary"
        return "01"
      end
  end
end

def get_tenant()
  return "010"
end

def get_object_type(provider)
  if provider.type == "ManageIQ::Providers::Vmware::InfraManager"
    return "34"
  elsif provider.type == "ManageIQ::Providers::Openstack::InfraManager"
    return "35"
  end
end

def get_os(template)
  # from template vendor
  template.tags.each do |tag|
    if tag.downcase.include? "linux" or tag.downcase.include? "rhel"
      return "03"
    elsif tag.downcase.include? "windows2012"
      return "01"
    elsif tag.downcase.include? "windows2016"
      return "02"
    end
  end
end

def get_node()
  return "1"
end

def get_app()
  return "1"
end

def get_provider(catalog_item)
  if catalog_item.tagged_with?("catalog_role", "primary")
    providers = $evm.vmdb(:ems_infra).find_tagged_with(:all => "provider_role/primary", :ns => "/managed")
    return providers.select { |p| p.type == "ManageIQ::Providers::Vmware::InfraManager" }.first
  elsif catalog_item.tagged_with?("catalog_role", "secondary")
    providers = $evm.vmdb(:ems_infra).find_tagged_with(:all => "provider_role/secondary", :ns => "/managed")
    return providers.select { |p| p.type == "ManageIQ::Providers::Vmware::InfraManager" }.first
  end
end

def get_vm_name_prefix()
  provider = get_provider($evm.root['service_template_provision_task'].source)
  task = $evm.root['service_template_provision_task']
  $evm.log(:info, "Got the following task options #{task.get_option(:dialog)}")
  template_name = task.get_option(:dialog)['dialog_template']
  templates = $evm.vmdb(:vm_or_template).find_tagged_with(:all => "template_os/#{template_name}", :ns => "/managed")
  template = templates.select { |t| t.ext_management_system.id == provider.id }.first
  source_site = get_source_site($evm.root['service_template_provision_task'].source)
  # get required
  region = get_region(provider)
  tenant = get_tenant()
  hypervisor = get_hypervisor(provider)
  environment = get_environment(task.get_option(:dialog)[:dialog_environment]) # ask faisal
  site = get_site(source_site, task.get_option(:dialog)[:dialog_dr_enabled], provider)
  os = get_os(template)
  app = get_app() # ask faisal
  node = get_node() # ask faisal
  seq = "$n{3}"

  vm_name = "#{region}#{tenant}#{hypervisor}#{environment}#{site}#{os}#{app}#{node}#{seq}"
  return vm_name
end


# Calls a user provided block for each grand child of the given parent.
#
# @param parent             Parent of grand children to call the given block for
# @block |grand_child_task| Call the given block for each grand child of the given parent
def for_each_grand_child_task(parent)
  parent.miq_request_tasks.each do |child_task|
    child_task.miq_request_tasks.each do |grand_child_task|
      # call block passing grand child MiqProvision
      yield grand_child_task
    end
  end
end

# Calls a user provided block for each alive (active, pending, queued) requests.
# Optionally does not call for the given current request.
#
# @param current_request             Optional. Current request to not call the block for.
# @param request_type                The type of alive requests to iterate over
# @block |active_or_pending_request| Call this block for each alive request.
def for_each_alive_request(current_request = nil, request_type = 'ServiceTemplateProvisionRequest')
  $evm.vmdb(:miq_request).all.each do |request|
    if ( (request.request_state == 'active' || request.request_state == 'pending' || request.request_state == 'queued') &&
         (request_type.nil? || request.type == request_type) &&
         (current_request.nil? || request.id != current_request.id) )

      # call block passing active/pending request
      yield request
    end
  end
end

# Given a ServiceTemplateProvisionRequest sets a lock option on that request signifying that the
# given request is doing VM naming with the given VM prefix.
#
# Before claiming the lock will first look for other active ServiceTemplateProvisionRequest that are either actively trying
# to get the lock or actually have the lock.
#
# In the case where any existing active ServiceTemplateProvisionRequest have the lock on the given vm_prefix or are trying
# to get the lock, then the given ServiceTemplateProvisionRequest will not get the lock. The caller of this function is then
# expected to try again.
#
# NOTE 1: This function does its best to approximate how a synchronize would work in Java in that the :vm_naming_lock_attempt option
# is checking to make sure only one thread concurrently attempts to get a lock while the :vm_naming_lock option is the actual lock to claim.
#
# @param current_request Current ServiceTemplateProvisionRequest attempt to get naming lock on given VM prefix
# @param vm_prefix       VM naming prefix to get a lock on
# @block                 Block of code to run if lock is acquired, block not run if lock is not acquired.
#
# @return True if the lock was acquired and given block executed. False if lock not acquired and user block not run.
def with_service_template_provision_request_naming_lock(current_request, vm_prefix)
  aquired_lock = false
  begin
    # set that the given request is trying to get the vm_naming lock
    $evm.log(:info, "Set lock attempt: { request_id => '#{current_request.id}', :vm_naming_lock_attempt => '#{vm_prefix}' }") if @DEBUG
    current_request.set_option(:vm_naming_lock_attempt, vm_prefix)

    # determine if any active ServiceTemplateProvisionRequests are trying to get a lock or have the lock for the given vm prefix
    $evm.log(:info, "Other Active ServiceTemplateProvisionRequests: { current_request_id => #{current_request.id} }") if @DEBUG
    existing_lock = false
    for_each_alive_request(current_request) do |request|
      request_vm_naming_lock_attempt = request.get_option(:vm_naming_lock_attempt)
      request_vm_naming_lock         = request.get_option(:vm_naming_lock)
      $evm.log(:info, "Found active ServiceTemplateProvisionRequest: { :id => #{request.id}, :vm_naming_lock_attempt => '#{request_vm_naming_lock_attempt}', :vm_naming_lock => '#{request_vm_naming_lock}' }") if @DEBUG

      # if the active ServiceTemplateProvisionRequest is trying to get lock or has lock, then this task can't have it
      if ( (!request_vm_naming_lock.nil? && request_vm_naming_lock == vm_prefix) ||
           (!request_vm_naming_lock_attempt.nil? && request_vm_naming_lock_attempt == vm_prefix) )

        # found existing request that already has lock
        $evm.log(:info, "Found active ServiceTemplateProvisionRequest with lock or attempting to get lock: { request_id => '#{request.id}', :vm_naming_lock_attempt => '#{request_vm_naming_lock_attempt}', :vm_naming_lock => '#{request_vm_naming_lock}' }") if @DEBUG
        existing_lock = true
        break
      end
    end

    # if another active ServiceTemplateProvisionRequest already has the lock or is trying to get the lock then can't get lock
    # else claim the lock
    if existing_lock
      $evm.log(:info, "ServiceTemplateProvisionRequest Failed to get lock: { request_id => '#{current_request.id}', :vm_naming_lock => '#{vm_prefix}' }") if @DEBUG
      aquired_lock = false
    else
      begin
        $evm.log(:info, "ServiceTemplateProvisionRequest Claim lock: { request_id => '#{current_request.id}', :vm_naming_lock => '#{vm_prefix}' }") if @DEBUG
        current_request.set_option(:vm_naming_lock, vm_prefix)
        aquired_lock = true

        # yield to the user block
        yield
      ensure
        $evm.log(:info, "ServiceTemplateProvisionRequest Release lock: { request_id => '#{current_request.id}', :vm_naming_lock => '#{vm_prefix}' }") if @DEBUG
        current_request.set_option(:vm_naming_lock, nil)
      end
    end
  ensure
    $evm.log(:info, "ServiceTemplateProvisionRequest Release lock attempt: { request_id => '#{current_request.id}', :vm_naming_lock_attempt => '#{vm_prefix}' }") if @DEBUG
    current_request.set_option(:vm_naming_lock_attempt, nil)
  end

  return aquired_lock
end

# Determines a unique VM name using the given VM name prefix, and optional given domain name,
# avoiding any names already in the given list.
#
# @param vm_prefix             VM name prefix for new VM
# @param domain_name           Domain name for new VM
# @param used_vm_names         List of VM names already used (not already in VMDB)
# @param suffix_counter_length Length of the counter to suffix the prefix with, ex 4 would mean '#{vm_prefix}0000'
def get_vm_name(vm_prefix, domain_name, used_vm_names, suffix_counter_length = DEFAULT_SUFFIX_COUNTER_LENGTH)
  suffix_counter_length ||= DEFAULT_SUFFIX_COUNTER_LENGTH
  counter_max = ("9" * suffix_counter_length).to_i
  vm_name = nil
  for i in (1..(counter_max+1))
    if i > counter_max
      error("Counter exceeded max (#{counter_max}) for prefix (#{vm_prefix})")
    else
      vm_name = "#{vm_prefix}#{i.to_s.rjust(suffix_counter_length, "0")}"

      # if domain name is given then append it to the VM name
      if !domain_name.nil?
        vm_name = "#{vm_name}.#{domain_name}"
      end

      # determine if VM already exists with generated name
      no_existing_vm_in_vmdb = $evm.vmdb('vm_or_template').find_by_name(vm_name).blank?
      not_in_used_vm_names   = !used_vm_names.include?(vm_name)
      $evm.log(:info, "get_vm_name: { vm_name => '#{vm_name}', no_existing_vm_in_vmdb => #{no_existing_vm_in_vmdb}, not_in_used_vm_names => #{not_in_used_vm_names} }") if @DEBUG

      # stop searching if no VM with given name already exists
      break if no_existing_vm_in_vmdb && not_in_used_vm_names
    end
  end

  $evm.log(:info, "get_vm_name: '#{vm_name}'") if @DEBUG
  return vm_name
end

begin
  $evm.log(:info, "START - set_vm_names") if @DEBUG

  # get the current ServiceTemplateProvisionTask
  task = $evm.root['service_template_provision_task']
  error("$evm.root['service_template_provision_task'] not found") if task.nil?
  $evm.log(:info, "Current ServiceTemplateProvisionTask: { :id => '#{task.id}', :miq_request_id => '#{task.miq_request.id}' }") if @DEBUG

  # get the VM name prefix
  vm_prefix = get_vm_name_prefix()


  # Get the domain name if one is set
  domain_name = "cloudtnt.com"

  # get the VM name suffix counter length
  vm_name_suffix_counter_length = 3

  #
  # IMPORTANT
  #   A lock is needed for generating the VM names in the case where two or more services get requested at the same time.
  #   Without this lock the two or more services could end up giving out the same VM names.
  #
  current_request = task.miq_request
  aquired_lock = with_service_template_provision_request_naming_lock(current_request, vm_prefix) do
    used_vm_names = []

    # get the VM names on all current active requests so as not to conflict with those
    $evm.log(:info, "Other Active ServiceTemplateProvisionRequests: { current_task_id => #{task.id}, current_request_id => #{current_request.id} }") if @DEBUG
    for_each_alive_request(current_request) do |request|
      $evm.log(:info, "\tActive ServiceTemplateProvisionRequest VM Names: { other_active_request_id => #{request.id} }") if @DEBUG

      for_each_grand_child_task(request) do |grand_child_task|
        existing_vm_target_name = grand_child_task.get_option(:vm_target_name)
        $evm.log(:info, "\t\tOther Active ServiceTemplateProvisionRequest VM name: { grand_child_task => #{grand_child_task.id}, existing_vm_target_name => '#{existing_vm_target_name}' }") if @DEBUG

        # add the concurrent service request VM name to the list of used vm names so there are no conflicts
        used_vm_names.push(existing_vm_target_name)
      end
    end

    # for each VM request generate a unique name and keep track of the names used in this batch
    for_each_grand_child_task(task) do |grand_child_task|
      # get the unique vm name
      vm_name = get_vm_name(vm_prefix, domain_name, used_vm_names, vm_name_suffix_counter_length)
      used_vm_names.push(vm_name)

      # set the target vm name
      grand_child_task.set_option(:vm_target_name, vm_name)
      grand_child_task.set_option(:vm_target_hostname, vm_name)
      grand_child_task.set_option(:vm_name, vm_name)

      $evm.log(:info, "Set grand_child_task options: { current_request_id => #{current_request.id}, grand_child_task_id => '#{grand_child_task.id}', :vm_target_name => '#{grand_child_task.get_option(:vm_target_name)}', :vm_target_hostname => '#{grand_child_task.get_option(:vm_target_hostname)}' }")
    end
  end

  # if did not acquire lock then retry after interval
  # else done
  unless aquired_lock
    $evm.log(:info, "Did not acquire VM naming lock '#{vm_prefix}', retry after interval '#{RETRY_INTERVAL}'")
    $evm.root['ae_result'] = 'retry'
    $evm.root['ae_retry_interval'] = "#{RETRY_INTERVAL}.seconds"
  else
    $evm.root['ae_result'] = 'ok'
  end

  $evm.log(:info, "END - set_vm_names") if @DEBUG
rescue => err
  error("[#{err}]\n#{err.backtrace.join("\n")}")
end
