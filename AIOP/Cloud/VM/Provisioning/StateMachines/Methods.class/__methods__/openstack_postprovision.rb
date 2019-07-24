# Get provisioning object
prov = $evm.root["miq_provision"]

# Call Turbo for workload placement
wp = $evm.instantiate("/Integration/Turbonomic/StateMachines/WorkloadPlacement?template=#{prov.options[:instance_type][1]}")
