dialog_hash = {}

# see if provider is already set in root
provider = $evm.root['ext_management_system']

if provider
  provider.flavors.each do |flavor|
    next unless flavor.ext_management_system || flavor.enabled
    dialog_hash[flavor.id] = "#{flavor.name} on #{flavor.ext_management_system.name}"
  end
end

choose = {''=>'< all flavors >'}
dialog_hash = choose.merge!(dialog_hash)

$evm.object["values"]     = dialog_hash
