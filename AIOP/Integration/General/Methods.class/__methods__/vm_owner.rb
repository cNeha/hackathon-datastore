$evm.vmdb('user').all.each { |x| $evm.log(:info, "#{x.userid}") }
$evm.vmdb('vm').all.each { |x| $evm.log(:info, "#{x.name} :#{x.userid}") }

#$evm.log(:info, "USER : ..........: #{user.first_name}")
