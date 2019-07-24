require 'rest-client'
require 'json'
require 'base64'

@user ||= $evm.root['user']

def get_opposite_provider(provider)
  role = ""
  if provider.tagged_with?("provider_role", "primary")
    role = "secondary"
  end
  if provider.tagged_with?("provider_role", "secondary")
    role = "primary"
  end
  $evm.vmdb(:ems_infra).find_tagged_with(:all => "provider_role/#{role}", :ns => "/managed")
  return providers.select { |p| p.type == "ManageIQ::Providers::Vmware::InfraManager" }.first
end

def get_opposite_template(template, provider)
  template_os = ""
  template.tags.each do |tag|
    fields = tag.split("/")
    if fields[0] == "template_os"
      template_os = fields[1]
    end
  end
  # get template tag value
  templates = $evm.vmdb(:vm_or_template).find_tagged_with(:all => "template_os/#{template_os}", :ns => "/managed")
  template = templates.select { |t| t.ext_management_system.id == provider.id }.first
  return template
end

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
      return "1"
    when "Pre-Production"
      return "2"
    when "Test"
       return "3"
    when "Development"
      return "4"
    when "Reserved"
      return "5"
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
        return "1"
      elsif not dr_enabled and current_site == "primary"
        return "1"
      elsif dr_enabled and current_site == "secondary"
        return "2"
      end
    when "secondary"
      if dr_enabled and current_site == "primary"
        return "2"
      elsif dr_enabled and current_site == "secondary"
        return "1"
      elsif not dr_enabled and current_site == "secondary"
        return "1"
      end
  end
end

def get_object_type(provider)
  if provider.type == "ManageIQ::Providers::Vmware::InfraManager"
    return "34"
  elsif provider.type == "ManageIQ::Providers::Openstack::CloudManager"
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

def yaml_data(task, option)
  task.get_option(option).nil? ? nil : YAML.load(task.get_option(option))
end

def get_vmware_datastores(provider, vm_count, sla)
  storages = Array.new
  provider.storages.each do |storage|
    if storage.tagged_with?("datastore_sla", sla)
      storages << storage
    end
  end
  if vm_count <= storages.length
    return storages.slice(0, vm_count)
  elsif vm_count > storages.length && !storages.empty?
    (0..vm_count - storages.length).step() do |n|
      storages << storages[n%(storages.length)]
    end
  end
    return storages
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

def get_source_site(catalog_item)
  if  catalog_item.tagged_with?("catalog_role", "primary")
    return "primary"
  elsif  catalog_item.tagged_with?("catalog_role", "secondary")
    return "secondary"
  end
end

begin
  task = $evm.root['service_template_provision_task']
  user = $evm.root['user']

  dialog_options = yaml_data(task, :parsed_dialog_options)
  dialog_options = dialog_options[0] if !dialog_options[0].nil?
  # TODO: multiselects dont get parsed, change to field name
  networks = nil
  begin
    networks = JSON.parse(task.options[:dialog]["Array::dialog_networks"])
  rescue  JSON::ParserError
    networks = task.options[:dialog]["Array::dialog_networks"].split(',')
  end
  tenant_name = dialog_options[:tenant]

  tenant_class = $evm.vmdb(:generic_object_definition).find_by_name("Tenant")
  tenant = tenant_class.find_objects(:name =>  tenant_name).first
  anti_affinity = dialog_options[:anti_affinity]
  #create_tenant_tag(tenant)

  app_class = $evm.vmdb(:generic_object_definition).find_by_name("Application")
  app = app_class.find_objects(:application_id =>  dialog_options[:app]).first

  dialog_tags = yaml_data(task, :parsed_dialog_tags)
  $evm.log(:info, "Got the following dialog_options_son #{dialog_options}")
  service = $evm.root['service_template_provision_task'].destination

  # Get provider
  provider = get_provider($evm.root['service_template_provision_task'].source)
  source_site = get_source_site($evm.root['service_template_provision_task'].source)

  template_name = dialog_options[:template]
  templates = $evm.vmdb(:vm_or_template).find_tagged_with(:all => "template_os/#{template_name}", :ns => "/managed")
  template = templates.select { |t| t.ext_management_system.id == provider.id }.first


  template_fields = {
    :name                => template.name,
    :request_type        => "clone_to_vm",
  }
  vm_fields = {
    # check cpu fields
    :number_of_sockets   => dialog_options[:cpu].to_s,
    :cores_per_socket    => "1",
    :vm_name             => 'changeme',
    :vm_memory           => (dialog_options[:memory].to_i * 1024).to_s,
    :vlan                => 'VM Network',
    :placement_auto      => true,
    :addr_mode           => "static",
    :sysprep_spec_override => true,
    :sysprep_enabled       => true,
  }
  requester = {
    # TODO: replace with user info
    :user_name           => @user.userid,
    :owner_first_name    => if @user.first_name then @user.first_name else "test" end,
    :owner_last_name     => if @user.last_name then @user.last_name else "test" end,
    :owner_email         => if @user.userid == "admin" then @user.email else @user.userid end,
    :auto_approve        => false
  }
  tags = {}
  additional_values = {
    :service_id => service.id,
    :nuage_subnets => networks,
    :source_site => get_source_site($evm.root['service_template_provision_task'].source),
    :tenant_id => tenant.attributes['properties']['tenant_id'],
    :tenant_name => dialog_options[:tenant],
    :tenant_generic_object_id => tenant.id,
    :app_name => app.name
  }
  ems_custom_attributes = {}
  miq_custom_attributes = {}


  number_of_vms = dialog_options[:number_of_vms].to_i
  datastore_sla = dialog_options[:datastore_sla].to_s

  datastores = get_vmware_datastores(provider, number_of_vms, datastore_sla)

  request_ids = Array.new
  number_of_vms.times do |count|
    vm_prefix = "#{get_region(provider)}#{tenant.attributes['properties']['tenant_id']}#{get_hypervisor(provider)}#{get_environment(dialog_options[:environment])}#{get_site(source_site, dialog_options[:dr_enabled], provider)}#{get_os(template)}#{dialog_options[:app]}#{count+1}"
    $evm.log(:info, "Vm prefix is #{vm_prefix}")
    vm_exists = $evm.vmdb(:miq_provision).all().pluck(:options).pluck(:vm_name).grep(/#{vm_prefix}/)
    sequence = "%.3d" % (count + 1).to_i
    if !vm_exists.empty?
      new_name = $evm.vmdb(:miq_provision).all().pluck(:options).pluck(:vm_name).grep(/#{vm_prefix}/).sort.last
      sequence = "%.3d" % (new_name[-3..-1].to_i + 1)
    end
    vm_name = "#{vm_prefix}#{sequence}"
    vm_fields[:vm_name] = vm_name
    vm_fields[:host_name] = "#{vm_name}"
    vm_fields[:linux_host_name] = "#{vm_name}"
    additional_values[:vm_index] = count.to_i + 1
    additional_values[:storage_id] = datastores[count].id
    provision_request = $evm.execute(
      'create_provision_request',
      "1.1",
      template_fields.stringify_keys,
      vm_fields.stringify_keys,
      requester.stringify_keys,
      tags.stringify_keys,
      additional_values.stringify_keys,
      ems_custom_attributes.stringify_keys,
      miq_custom_attributes.stringify_keys
    )
    approval_user = $evm.vmdb(:user).find_by_name(task.miq_request.v_approved_by)
    provision_request.approve(approval_user.userid, task.miq_request.reason)
    request_ids << provision_request.id
  end

  provision_request_ids = task.get_option(:provision_request_ids) || {}
  provision_request_ids = provision_request_ids.values
  request_ids.each do |request_id|
    provision_request_ids << request_id
  end
  provision_request_ids_hash = {}
  provision_request_ids.each_with_index { |id, index| provision_request_ids_hash[index] = id }
  task.set_option(:provision_request_ids, provision_request_ids_hash)

  # if dialog_options[:dr_enabled]
  #   template = get_opposite_template(provider)
  #   provider = template.ext_management_system
  #   # TODO: update post_params and then send request
  # end

end
