# inputs tenant name
# input tenant_id

# get from dialog tenant_name =
# get from dialog tenant_id =
# if openstack create real tenant in openstack
require 'fog/openstack'
require 'rest-client'
require 'json'
require "base64"
require 'net/ldap'

@PARENT_TENANT_ID = "99000000000001"
@cfme_user = $evm.object['cfme_user']
@cfme_password = $evm.object.decrypt('cfme_password')
@master_ip = $evm.object['master_ip']

@ad_ip = $evm.object['ad_ip']
@ad_user = $evm.object['ad_user']
@ad_password =$evm.object.decrypt('ad_password')

def add_ldap_group(group_name)
  server = {
    :host => @ad_ip,
    :base => 'ou=Service Accounts,dc=incloudtnt,dc=com',
    :port => 389,
    :encryption => :simple,
    :auth => {
      :method => :simple,
      :username => @ad_user,
      :password => @ad_password,
    }
  }
  ldap = Net::LDAP.new(server)
  ldap.bind

  dn = "cn=#{group_name},OU=Security Groups,OU=Groups,DC=incloudtnt,DC=com"
  attrs = {
    :cn => "#{group_name}",
    :samaccountname => "#{group_name}",
    :objectclass => "Group",
  }
  ldap.add(:dn => dn, :attributes => attrs)

  # Fetch RH admin users and add them to new group
  result = ldap.search(
    :base => "OU=Security Groups,OU=Groups,DC=incloudtnt,DC=com",
    :filter => Net::LDAP::Filter.eq( "cn", "RH.CF-ADMINS"),
    :return_result => true
  )[0]

  result[:member].each do |member|
    ldap.modify(
      :dn => "cn=#{group_name},OU=Security Groups,OU=Groups,DC=incloudtnt,DC=com",
      :operations => [ [ :add, :member, member ] ]
    )
  end
end

def create_local_tenant(ip, tenant_name, parent_id)
  post_params = {
    "action" => "create",
    "resource" => {
      "name" => tenant_name,
      "description" => tenant_name,
      "parent" => {"id" => parent_id}
    }
  }
  $evm.log(:info, "Posting tenant_dict #{post_params}")
  api_uri = "https://#{ip}/api"
  url = URI.encode(api_uri + '/auth')
  rest_return = RestClient::Request.execute(
                            :method => "get",
                            :url =>        url,
                            :user       => @cfme_user,
                            :password   => @cfme_password,
                            :headers    => {:accept => :json},
                            :verify_ssl => false)
  auth_token = JSON.parse(rest_return)['auth_token']

  url = URI.encode(api_uri + '/tenants')
  rest_return = RestClient::Request.execute(
                            :method =>     "post",
                            :url =>        url,
                            :headers    => {:accept        => :json,
                                            'x-auth-token' => auth_token},
                            :payload    => post_params.to_json,
                            :verify_ssl => false)
  return JSON.parse(rest_return)["results"][0]["id"]
  # TODO: JSON parse and return ID

end


def create_local_group(ip, tenant_local_id, tenant_name, tenant_admin_role_id)
  #@master_ip = "10.216.41.12"
  post_params = {
    "action" => "create",
    "resource" => {
      "description" => "#{tenant_name}",
      "role" => { "href" => "https://#{ip}/api/roles/#{tenant_admin_role_id}" },
      "tenant" => { "href" => "https://#{ip}/api/tenants/#{tenant_local_id}" }
    }
  }
  $evm.log(:info, "Posting group_dict #{post_params}")

  api_uri = "https://#{ip}/api"
  url = URI.encode(api_uri + '/auth')
  rest_return = RestClient::Request.execute(
                            :method => "get",
                            :url =>        url,
                            :user       => @cfme_user,
                            :password   => @cfme_password,
                            :headers    => {:accept => :json},
                            :verify_ssl => false)
  auth_token = JSON.parse(rest_return)['auth_token']

  url = URI.encode(api_uri + '/groups')
  rest_return = RestClient::Request.execute(
                            :method =>     "post",
                            :url =>        url,
                            :headers    => {:accept        => :json,
                                            'x-auth-token' => auth_token},
                            :payload    => post_params.to_json,
                            :verify_ssl => false)

end

def yaml_data(task, option)
  task.get_option(option).nil? ? nil : YAML.load(task.get_option(option))
end

task = $evm.root['service_template_provision_task']
user = $evm.root['user']

dialog_options = yaml_data(task, :parsed_dialog_options)
dialog_options = dialog_options[0] if !dialog_options[0].nil?

tenant_class = $evm.vmdb(:generic_object_definition).find_by_name("Tenant")
tenant = tenant_class.find_objects(:name =>  dialog_options[:tenant_name]).first

if not tenant.nil?
  $evm.root['ae_result'] = 'error'
  $evm.root['ae_reason'] = "Tenant name already exists"
  $evm.log(:error, "Tenant exists!")
  exit MIQ_OK
end

# TODO:  add id check aslo
tenant = tenant_class.create_object(
  :tenant_id => dialog_options[:tenant_id],
  :name =>  dialog_options[:tenant_name]
)


fields = [
  #{"parent_tenant_id" => "99000000000001", "ip" => "10.216.41.11", "tenant_admin_role_id" => "99000000000013"},
  {"parent_tenant_id" => "10000000000001", "ip" => "10.216.45.11", "tenant_admin_role_id" => "10000000000013"}
  #TODO add subregion
]

fields.each do |dict|
  tenant_id = create_local_tenant(dict["ip"], dialog_options[:tenant_name], dict["parent_tenant_id"])
  create_local_group(dict["ip"], tenant_id, "RH.CF-#{dialog_options[:tenant_name]}-ADMINS", dict["tenant_admin_role_id"])
end

add_ldap_group("RH.CF-#{dialog_options[:tenant_name]}-ADMINS")
#create_tenant_in_subregions()
# TODO: create group in LDAP
#svc = MiqAeMethodService::MiqAeServiceService.create(name: 'Service 2', description: 'lorem ipsum', miq_group: 1)
#svc.display = true      # This is important, since it will be invisible by default
#create tenant is OSP

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

