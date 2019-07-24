require 'fog/openstack'

def yaml_data(task, option)
  task.get_option(option).nil? ? nil : YAML.load(task.get_option(option))
end

def get_fog_object(provider, type, tenant)
  endpoint='publicURL'
  (provider.api_version == 'v2') ? (conn_ref = '/v2.0/tokens') : (conn_ref = '/v3/auth/tokens')
  (provider.security_protocol == 'non-ssl') ? (proto = 'http') : (proto = 'https')

  connection_hash = {
    :provider => 'OpenStack',
    :openstack_api_key => provider.authentication_password,
    :openstack_username => provider.authentication_userid,
    :openstack_auth_url => "#{proto}://#{provider.hostname}:#{provider.port}#{conn_ref}",
    # in a OSPd environment, this might need to be commented out depending on accessibility of endpoints
    :openstack_endpoint_type => endpoint,
    :openstack_tenant => tenant,
  }
  # if the openstack environment is using keystone v3, add two keys to hash and replace the auth_url
  if provider.api_version == 'v3'
    connection_hash[:openstack_domain_name] = 'Default'
    connection_hash[:openstack_project_name] = tenant
    connection_hash[:openstack_auth_url] = "#{proto}://#{provider.hostname}:5000/#{conn_ref}"
  end
  return Object::const_get("Fog").const_get("#{type}").new(connection_hash)
end

dialog_options = yaml_data(task, :parsed_dialog_options)
dialog_options = dialog_options[0] if !dialog_options[0].nil?
tenant_name = dialog_options[:tenant_name]

$evm.vmdb(:ems_cloud).all().each do |provider|

  openstack_keystone = get_fog_object(provider, 'Identity', "admin")
  openstack_keystone.projects.create(
    {
      :description => "CloudForms created project #{tenant_name}",
      :enabled => true,
      :name => tenant_name
    }
  )

end
