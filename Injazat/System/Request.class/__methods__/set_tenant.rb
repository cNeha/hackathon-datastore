require 'fog/openstack'
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

$evm.vmdb(:ems_cloud).all().each do |provider|
  tenant_name = "tostos"
  openstack_keystone = get_fog_object(provider, 'Identity', "admin")
  openstack_keystone.create_tenant(
    {
      :description => "CloudForms created project #{tenant_name}",
      :enabled => true,
      :name => tenant_name
    }
  )

end
