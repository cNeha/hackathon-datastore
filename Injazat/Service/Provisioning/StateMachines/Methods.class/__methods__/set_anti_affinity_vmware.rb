require 'rest-client'
require 'json'

@PRIMARY_AFFINITY_JOB_ID = "10000000000004"
@SECONDARY_AFFINITY_JOB_ID = ""
ANSIBLE_NAMESPACE = 'AutomationManagement/AnsibleTower/Operations/StateMachines'.freeze
ANSIBLE_STATE_MACHINE_CLASS = 'Job'.freeze
ANSIBLE_STATE_MACHINE_INSTANCE = 'default'.freeze

def launch_drs_job(vms, cluster_name, rule_name, job_id)
  attrs = {}
  attrs['job_template_id'] = job_id
  attrs['dialog_param_vms'] = vms
  attrs['dialog_param_cluster_name'] = cluster_name
  attrs['dialog_param_rule_name'] = rule_name

  options = {}
  options[:namespace]     = ANSIBLE_NAMESPACE
  options[:class_name]    = ANSIBLE_STATE_MACHINE_CLASS
  options[:instance_name] = ANSIBLE_STATE_MACHINE_INSTANCE
  options[:user_id]       = $evm.root['user'].id
  options[:attrs]         = attrs
  auto_approve            = true
  $evm.execute('create_automation_request', options, $evm.root['user'].userid, auto_approve)
end

def yaml_data(task, option)
  task.get_option(option).nil? ? nil : YAML.load(task.get_option(option))
end

task = $evm.root['service_template_provision_task']
user = $evm.root['user']
catalog_item = $evm.root['service_template_provision_task'].source

dialog_options = yaml_data(task, :parsed_dialog_options)
dialog_options = dialog_options[0] if !dialog_options[0].nil?

anti_affinity = dialog_options[:anti_affinity]
provision_request_ids = task.get_option(:provision_request_ids).values

@PRIMARY_ZONE_ID = "10"
@SECONDARY_ZONE_ID = "11"

primary_vm_names = Array.new
secondary_vm_names = Array.new
primary_cluster_name = ""
secondary_cluster_name = ""

provision_request_ids.each do |request_id|
  prov_request = $evm.vmdb(:miq_provision_request).find_by_id(request_id)
  if prov_request.miq_request.region_number.to_s == @PRIMARY_ZONE_ID
    primary_vm_names << prov_request.options[:vm_name]
    vm = $evm.vmdb(:vm).find_by_name(prov_request.options[:vm_name].to_s)
    primary_cluster_name = vm.ems_cluster.name
  end
  if prov_request.miq_request.region_number.to_s == @SECONDARY_ZONE_ID
    secondary_vm_names << prov_request.options[:vm_name]
    vm = $evm.vmdb(:vm).find_by_name(prov_request.options[:vm_name].to_s)
    secondary_cluster_name = vm.ems_cluster.name
  end
end

if !primary_vm_names.empty? and anti_affinity and primary_vm_names.length > 1
  launch_drs_job(primary_vm_names, primary_cluster_name, task.id.to_s, @PRIMARY_AFFINITY_JOB_ID)
end

if !secondary_vm_names.empty? and anti_affinity and secondary_vm_names.length > 1
  launch_drs_job(secondary_vm_names, secondary_cluster_name, task.id.to_s, @SECONDARY_AFFINITY_JOB_ID)
end
