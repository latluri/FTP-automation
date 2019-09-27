#!/bin/sh


str=$(hadoop fs -cat /user/${USER}/sftgdia_qa/sftgdia_qa_properties.txt)
IFS=" " read HOST USER_ID PASSWORD <<< $str



/usr/bin/expect<<EOD
spawn sftp -i sftgdiakey_qa_private_key  $USER_ID@$HOST
expect "password:"
send "$PASSWORD\r"
expect "sftp>"
send "cd ${1}\r"
expect "sftp>"
send "ls -l\r"
expect "sftp>"
send "bye\r"
EOD


