def yaml_data(task, option)
  task.get_option(option).nil? ? nil : YAML.load(task.get_option(option))
end

task = $evm.root['service_template_provision_task']
user = $evm.root['user']

dialog_options = yaml_data(task, :parsed_dialog_options)
dialog_options = dialog_options[0] if !dialog_options[0].nil?

application_class = $evm.vmdb(:generic_object_definition).find_by_name("Application")
application = application_class.find_objects(:name => dialog_options[:application_name]).first

if application
  $evm.root['ae_result'] = 'error'
  $evm.root['ae_reason'] = "Application name already exists"
  $evm.log(:error, msg)
  exit MIQ_OK
end

application = application_class.create_object(
  :application_id => dialog_options[:application_id],
  :name =>  dialog_options[:application_name]
)
