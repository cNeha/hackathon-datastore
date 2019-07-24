#
# Description: <Method description here>
#
###################################
#
# EVM Automate Method: expand_disk
#
# Notes: This method is used to increase the size of a VMWare VM disks.
#
# Inputs: $evm.root['vm'], dialog_size(GB)
#
###################################
begin
  # Method for logging
  def log(level, message)
    @method = 'expand_disk'
    $evm.log(level, "#{@method} - #{message}")
  end

  # dump_root
  def dump_root()
    log(:info, "Root:<$evm.root> Begin $evm.root.attributes")
    $evm.root.attributes.sort.each { |k, v| log(:info, "Root:<$evm.root> Attribute - #{k}: #{v}")}
    log(:info, "Root:<$evm.root> End $evm.root.attributes")
    log(:info, "")
  end

  log(:info, "CFME Automate Method Started")

  # dump all root attributes to the log
  dump_root

  def ensure_vm_available(vm_base, ems)
    unavailable_reason = false
    %w(ems vm_base).each do |nillable|
      if eval(nillable).nil?
        unavailable_reason = nillable
        break
      end
    end

    automate_retry(30, "#{unavailable_reason} is not available.") if unavailable_reason
  end

  def resizeDisk(vm, disk_number, new_disk_size_in_kb)
    vm_base = vm.object_send('instance_eval', 'self')
    ems = vm.ext_management_system

    ensure_vm_available vm_base, ems

    ems.object_send('instance_eval', '
  def resize_disk(vm, diskIndex, new_disk_size_in_kb)
    #self.get_vim_vm_by_mor(vm.ems_ref) do | vimVm |
    vm.with_provider_object do | vimVm |
      devices = vimVm.send(:getProp, "config.hardware")["config"]["hardware"]["device"]

      matchedDev = nil
      currentDiskIndex = 0
      devices.each do | dev |
        next if dev.xsiType != "VirtualDisk"
        if diskIndex == currentDiskIndex
          matchedDev = dev
          break
        end
        currentDiskIndex += 1
      end
      raise "resize_disk: disk #{diskIndex} not found" unless matchedDev
      $log.info("resize_disk: resizing using matched device at #{diskIndex}")

      vmConfigSpec = VimHash.new("VirtualMachineConfigSpec") do |vmcs|
        vmcs.deviceChange = VimArray.new("ArrayOfVirtualDeviceConfigSpec") do |vmcs_vca|
          vmcs_vca << VimHash.new("VirtualDeviceConfigSpec") do |vdcs|
            vdcs.operation = "edit".freeze
            vdcs.device    = VimHash.new("VirtualDisk") do |vDev|
              vDev.key           = matchedDev["key"]
              vDev.controllerKey = matchedDev["controllerKey"]
              vDev.unitNumber    = matchedDev["unitNumber"]
              vDev.backing       = matchedDev["backing"]
              vDev.capacityInKB  = new_disk_size_in_kb
            end
          end
        end
      end
      $log.info("resize_disk: attempting to reconfigure vm with spec: \'#{vmConfigSpec}\'")
      vimVm.send(:reconfig, vmConfigSpec)
    end
  end')
    ems.object_send('resize_disk', vm_base, disk_number, new_disk_size_in_kb)
  end

  def automate_retry(seconds, reason)
    $evm.root['ae_result'] = 'retry'
    $evm.root['ae_retry_interval'] = "#{seconds.to_i}.seconds"
    $evm.root['ae_reason'] = reason

    log(:info, "Retrying #{@method} after #{seconds} seconds, because '#{reason}'")
    exit MIQ_OK
  end

  # Dump all root object attributes
  automate_retry(30, "$evm.root not yet ready.") if $evm.root.nil?

  # Get dialog_disk_number variable from root hash if nil convert to zero
  DISK_NUMBER = $evm.root['dialog_diskindex'].to_i
  log(:info,"DISK_NUMBER: '#{DISK_NUMBER}'")

  vm = $evm.root['vm']
  raise "VM object not found" if vm.nil?

  # This method only works with VMware VMs currently
  raise "Invalid vendor: #{vm.vendor}" unless vm.vendor.downcase == 'vmware'

  sizeGB = $evm.root['dialog_disksize'].to_i

  log(:info,"Detected VM:'#{vm.name}' vendor:'#{vm.vendor}' DISK_NUMBER:'#{DISK_NUMBER}' sizeGB:'#{sizeGB}'")
  log(:info, "Expanding disk to #{sizeGB}GB")
   new_disk_size_in_kb = (sizeGB * 1024**2)
    begin
      resizeDisk(vm, DISK_NUMBER, new_disk_size_in_kb)
    rescue => e
      if e.message =~ /VimFault/
        log(:warn, "Encountered VimFault: #{e.inspect}")
        automate_retry(30, "Encountered VimFault #{e.inspect}")
      end

      log(:error, "e: #{e}")
      log(:error, "e.inspect: #{e.inspect}")
      log(:error,"[#{e}]\n#{e.backtrace.join("\n")}")
      log(:error, "e.message: #{e.message}")
    end

  log(:info,"EVM Automate Method Ended")
  exit MIQ_OK

    #
    # Set Ruby rescue behavior
    #
rescue => err
  $evm.log("error","[#{err}]\n#{err.backtrace.join("\n")}")
  exit MIQ_ABORT
end
