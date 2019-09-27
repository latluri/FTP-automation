#!/bin/sh


str=$(hadoop fs -cat /user/${USER}/ihs_ftp_polk_maketingsystems_prod/ihs_ftp_polk_maketingsystems_prod_properties.txt)
IFS=" " read HOST USER_ID PASSWORD <<< $str



/usr/bin/expect<<EOD
spawn ftp proxyvipecc.nb.ford.com
expect "Name"
send "$USER_ID@$HOST\r"
expect "Password:"
send "$PASSWORD\r"
expect "ftp>"
send "cd ${1}\r"
expect "ftp>"
send "ls -l\r"
expect "ftp>"
send "bye\r"
EOD


