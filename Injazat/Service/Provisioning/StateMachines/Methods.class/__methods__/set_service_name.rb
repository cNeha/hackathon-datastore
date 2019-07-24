def yaml_data(task, option)
  task.get_option(option).nil? ? nil : YAML.load(task.get_option(option))
end

task = $evm.root['service_template_provision_task']
user = $evm.root['user']

dialog_options = yaml_data(task, :parsed_dialog_options)
dialog_options = dialog_options[0] if !dialog_options[0].nil?

service = $evm.vmdb('service', task.destination_id)
timestamp = Time.now.iso8601.gsub(/\W/, '').gsub('T','')[0..-7]

service.name = "#{service.name} #{dialog_options[:tenant]} #{timestamp}"
