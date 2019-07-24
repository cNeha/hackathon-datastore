ipaddr = "10.74.120.123"
$evm.log("info", "...................................>>>>>>")
cmd = "/var/www/miq/vmdb/hello.sh #{ipaddr}"
result=`#{cmd}`
$evm.log("info", "RESULT>>>>>>>>>>>>>>>>>>> #{result}")

