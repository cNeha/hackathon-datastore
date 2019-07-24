=begin
temmplateUuid 				(O)
numVCPUs 					(R) VirtualMachine
vMemSize 					(R) VirtualMachine
vStorageSize 				(R) VirtualMachine
networkThroughputConsumed	(R) VirtualMachine
ioThroughputConsumed		(R) VirtualMachine
accessSpeedConsumed			(R) VirtualMachine
memConsumedFactor			(R) VirtualMachine
cpuConsumedFactor			(R) VirtualMachine
storageConsumedFactor		(R) VirtualMachine
numCores					(R) PhysicalMachine
cpuCoreSpeed				(R) PhysicalMachine
memSize						(R) PhysicalMachine
networkThroughputSize		(R) PhysicalMachine
ioThroughputSize			(R) PhysicalMAchine
storageSize					(R) Storage
vendor						(R) Storage
model						(R) Storage
price						(R) Storage
desc						(R) Storage
=end

payload = $evm.object['payload'].nil? ? {} : $evm.object['payload']
payload[:temmplateUuid] 			= $evm.object['temmplateUuid'] unless $evm.object['temmplateUuid'].nil? or $evm.object['temmplateUuid'].empty?
payload[:numVCPUs] 					= $evm.object['numVCPUs'] unless $evm.object['numVCPUs'].nil? or $evm.object['numVCPUs'].empty?
payload[:vMemSize] 					= $evm.object['vMemSize'] unless $evm.object['vMemSize'].nil? or $evm.object['vMemSize'].empty?
payload[:vStorageSize] 				= $evm.object['vStorageSize'] unless $evm.object['vStorageSize'].nil? or $evm.object['vStorageSize'].empty?
payload[:networkThroughputConsumed] = $evm.object['networkThroughputConsumed'] unless $evm.object['networkThroughputConsumed'].nil? or $evm.object['networkThroughputConsumed'].empty?
payload[:ioThroughputConsumed] 		= $evm.object['ioThroughputConsumed'] unless $evm.object['ioThroughputConsumed'].nil? or $evm.object['ioThroughputConsumed'].empty?
payload[:accessSpeedConsumed] 		= $evm.object['accessSpeedConsumed'] unless $evm.object['accessSpeedConsumed'].nil? or $evm.object['accessSpeedConsumed'].empty?
payload[:memConsumedFactor] 		= $evm.object['memConsumedFactor'] unless $evm.object['memConsumedFactor'].nil? or $evm.object['memConsumedFactor'].empty?
payload[:cpuConsumedFactor] 		= $evm.object['cpuConsumedFactor'] unless $evm.object['cpuConsumedFactor'].nil? or $evm.object['cpuConsumedFactor'].empty?
payload[:storageConsumedFactor] 	= $evm.object['storageConsumedFactor'] unless $evm.object['storageConsumedFactor'].nil? or $evm.object['storageConsumedFactor'].empty?
payload[:numCores] 					= $evm.object['numCores'] unless $evm.object['numCores'].nil? or $evm.object['numCores'].empty?
payload[:cpuCoreSpeed] 				= $evm.object['cpuCoreSpeed'] unless $evm.object['cpuCoreSpeed'].nil? or $evm.object['cpuCoreSpeed'].empty?
payload[:memSize] 					= $evm.object['memSize'] unless $evm.object['memSize'].nil? or $evm.object['memSize'].empty?
payload[:networkThroughputSize] 	= $evm.object['networkThroughputSize'] unless $evm.object['networkThroughputSize'].nil? or $evm.object['networkThroughputSize'].empty?
payload[:ioThroughputSize] 			= $evm.object['ioThroughputSize'] unless $evm.object['ioThroughputSize'].nil? or $evm.object['ioThroughputSize'].empty?
payload[:storageSize] 				= $evm.object['storageSize'] unless $evm.object['storageSize'].nil? or $evm.object['storageSize'].empty?
payload[:vendor] 					= $evm.object['vendor'] unless $evm.object['vendor'].nil? or $evm.object['vendor'].empty?
payload[:model] 					= $evm.object['model'] unless $evm.object['model'].nil? or $evm.object['model'].empty?
payload[:price] 					= $evm.object['price'] unless $evm.object['price'].nil? or $evm.object['price'].empty?
payload[:desc] 						= $evm.object['desc'] unless $evm.object['desc'].nil? or $evm.object['desc'].empty?

uri                     = "templates/#{$evm.object['template_name']}"
$evm.object['result']	= ""

client = $evm.instantiate("/Integration/RestClients/Turbonomic?method=#{$evm.object['method']}&uri=#{uri}&payload=#{payload.to_json}")
$evm.object['result'] = client['result']
