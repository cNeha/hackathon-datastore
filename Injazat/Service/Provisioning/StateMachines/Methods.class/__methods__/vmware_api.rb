require 'rest-client'
require 'json'
require 'base64'

@user ||= $evm.root['user']

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
      elsif dr_enabled and current_site = "secondary"
        return "2"
      end
    when "secondary"
      if dr_enabled and current_site == "primary"
        return "2"
      elsif dr_enabled and current_site = "secondary"
        return "1"
      elsif not dr_enabled and current_site = "secondary"
        return "1"
      end
  end
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

def yaml_data(task, option)
  task.get_option(option).nil? ? nil : YAML.load(task.get_option(option))
end

def get_vmware_hosts(vm_count, provider)
  sorted_hosts = Array.new
  # filter hosts beforehand with ones tagged
  provider.hosts.each do |h|
    memory_used_percentage = h.hardware.memory_usage / h.hardware.memory_mb.to_f
    sorted_hosts << {
      "memory_used_percentage" => memory_used_percentage,
      "host_id" => h.id
    }
  end
  sorted_hosts.sort_by! { |hsh| hsh[:memory_used_percentage] }
  sorted_hosts_obj = Array.new
  sorted_hosts.each do |h|
    sorted_hosts_obj << $evm.vmdb(:host).find_by(:id => h["host_id"])
  end
  if vm_count <= sorted_hosts_obj.length
    return sorted_hosts_obj.slice(0, vm_count)
  elsif vm_count > sorted_hosts_obj.length && !hosts.empty?
    (0..vm_count - sorted_hosts_obj.length).step() do |n|
      sorted_hosts_obj << sorted_hosts_obj[n%(sorted_hosts_obj.length)]
    end
  end
    return sorted_hosts_obj
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

def get_miqserver(template)
  zone_id = template.ext_management_system.zone_id
  zone = $evm.vmdb(:zone).find_by(:id => zone_id)
  miq_server  = $evm.vmdb(:miq_server).where(:zone_id=> zone.id).first
  return miq_server
end

def create_provision_request_api(ip, post_params)
  api_uri = "https://#{ip}/api"
  url = URI.encode(api_uri + '/auth')
  rest_return = RestClient::Request.execute(
    :method => "get",
    :url => url,
    :user => "admin",
    :password => "smartvm",
    :headers => {:accept => :json},
    :verify_ssl => false
  )
  auth_token = JSON.parse(rest_return)['auth_token']

  url = URI.encode(api_uri + '/provision_requests')
  rest_return = RestClient::Request.execute(
    :method => "post",
    :url => url,
    :headers => {
      :accept => :json,
      'x-auth-token' => auth_token
    },
    :payload => post_params,
    :verify_ssl => false
  )
  result = JSON.parse(rest_return)

  return result['results'][0]['id']
end


begin
  task = $evm.root['service_template_provision_task']
  user = $evm.root['user']

  dialog_options = yaml_data(task, :parsed_dialog_options)
  dialog_options = dialog_options[0] if !dialog_options[0].nil?
  # TODO: multiselects dont get parsed, change to field name
  networks = JSON.parse(task.options[:dialog]["Array::dialog_networks"])
  tenant_name = dialog_options[:tenant]

  tenant_class = $evm.vmdb(:generic_object_definition).find_by_name("Tenant")
  tenant = tenant_class.find_objects(:name =>  tenant_name).first
  anti_affinity = dialog_options[:anti_affinity]
  #create_tenant_tag(tenant)

  dialog_tags = yaml_data(task, :parsed_dialog_tags)
  $evm.log(:info, "Got the following dialog_options_son #{dialog_options}")
  service = $evm.root['service_template_provision_task'].destination

  # Get provider
  provider = get_provider($evm.root['service_template_provision_task'].source)
  source_site = get_source_site($evm.root['service_template_provision_task'].source)

  template_name = dialog_options[:template]
  #template = $evm.vmdb(:vm_or_template).find_by(:name => template_name, :template => true)
  templates = $evm.vmdb(:vm_or_template).find_tagged_with(:all => "template_os/#{template_name}", :ns => "/managed")
  template = templates.select { |t| t.ext_management_system.id == provider.id }.first

  miq_server  = get_miqserver(template)

  post_params = {
    'version'               => '1.1',
    'template_fields'       => {
      'name'                => template.name,
      'request_type'        => 'template'
    },
    'vm_fields'             => {
      'number_of_cpus'      => '1',
      'vm_name'             => 'changeme',
      'vm_memory'           => '2048',
      'vlan'                => 'VM Network',
      'placement_auto'      => true
    },
    'requester'             => {
      # TODO: replace with user info
      'user_name'           => @user.userid,
      'owner_first_name'    => if @user.first_name then @user.first_name else "test" end,
      'owner_last_name'     => if @user.last_name then @user.last_name else "test" end,
      'owner_email'         => if @user.userid == "admin" then @user.email else @user.userid end,
      'auto_approve'        => true
    },
    'tags'                  => {
    },
    'additional_values'     => {
      'service_id' => service.id,
      'nuage_subnets' => networks,
      'source_site' => get_source_site($evm.root['service_template_provision_task'].source),
      'tenant_id' => tenant.attributes['properties']['tenant_id'],
      'tenant_name' => dialog_options[:tenant],
      'tenant_generic_object_id' => tenant.id
    },
    'ems_custom_attributes' => {},
    'miq_custom_attributes' => {}
  }


  number_of_vms = dialog_options[:number_of_vms].to_i
  datastore_sla = dialog_options[:datastore_sla].to_s

  hosts = get_vmware_hosts(number_of_vms, provider)
  datastores = get_vmware_datastores(provider, number_of_vms, datastore_sla)

  request_ids = Array.new
  number_of_vms.times do |count|
    vm_prefix = "#{get_region(provider)}#{tenant.attributes['properties']['tenant_id']}#{get_hypervisor(provider)}#{get_environment(dialog_options[:environment])}#{get_site(source_site, dialog_options[:dr_enabled], provider)}#{get_os(template)}#{dialog_options[:app]}#{count+1}"
    vm_exists = $evm.vmdb(:vm).where("name like ?", "%#{vm_prefix}%").last
    sequence = "%.3d" % (count + 1).to_i
    if vm_exists
      new_name = $evm.vmdb(:vm).where("name like ?", "%#{vm_prefix}%").pluck(:name).sort.last
      sequence = "%.3d" % (new_name[-3..-1].to_i + count + 1)
    end
    vm_name = "#{vm_prefix}#{sequence}"
    post_params["vm_fields"]["vm_name"] = vm_name
    post_params ["additional_values"]["vm_index"] = count.to_i + 1
    post_params["vm_fields"]["placement_ds_name"] = datastores[count].id
      # post_params["vm_fields"]["placement_cluster_name"] = hosts[count].ems_cluster_id
      # post_params["vm_fields"]["placement_auto"] = false
    request_ids << create_provision_request_api(miq_server.ipaddress, post_params.to_json)
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
  #   zone_id = template.ext_management_system.zone_id
  #   zone = $evm.vmdb(:zone).find_by(:id => zone_id)
  #   miq_server  = $evm.vmdb(:miq_server).where(:zone_id=> zone.id).first
  #   # TODO: update post_params and then send request
  # end

end
