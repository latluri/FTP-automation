#!/bin/sh

today_=`date "+%Y-%m-%d"`

mail_to="latluri1@ford.com"
from_gechub_folder="out"
default_dir="/project/dz/collab/DataAcquisition/sftgdia_new_files_received"
failed_file_dir="/project/dz/collab/DataAcquisition/sftgdia_failed_files"


get_destination_dir() {
destinations=$(hdfs dfs -cat /user/${USER}/SFTGDIA/destination_folders.txt)

for i21 in ${destinations}
do
pattern=$(echo ${i21} | awk -F'|' '{print $1}')
folder=$(echo ${i21} | awk -F'|' '{print $2}')

echo ${1} |grep -q -i ${pattern}

if [ $? == 0 ]
then
echo "$folder"
fi
done
}




##############
sh check_files.sh ${from_gechub_folder} |sed -n '/ls -l/,$p' |grep -v "^sftp"|awk -F' ' '{print $5"|"$9}'|sed "s/\r//g"> check_files_output.txt
#dos2unix check_files_output.txt

files=$(cat check_files_output.txt)
no_of_files=`cat check_files_output.txt|wc -l`

#echo ${files}

if [ -z "${files}" ]
then
echo "SFTGDIA QA, No  files to load on ${today_}" |mailx -s "SFTGDIA QA No found to load" ${mail_to}
exit 0;
else
echo -e "SFTGDIA, QA found ${no_of_files} file(s) to load.\n$(cat check_files_output.txt)" >> summary.txt #|mailx -s "SFTGDIA, QA found files on ${today_}" latluri1@ford.com
fi


for i in ${files}
do
#echo ${i}
size_file=`echo ${i}|awk -F'|' '{print $1}'`
file_name=`echo ${i}|awk -F'|' '{print $2}'`
file_name_renamed=`echo ${i}|awk -F'|' '{print $2}'|sed 's/%/__/g'`
#echo $file_name,$size_file
sh get_file.sh ${from_gechub_folder} ${file_name}
actual_size=`ls -l /s/sftgdia/${file_name}| awk -F' ' '{print $5}'`

k=1;

while [ "$size_file" != "$actual_size" -a "${k}" -lt 5 ]
do

k=` expr "${k}" + 1 `;
echo "file ${file_name} not loaded successfully, expeted size ${size_file} but downloaded size ${actual_size} re-trying. Attempt number ${k}"
sh get_file.sh ${from_gechub_folder} ${file_name} -a
actual_size=`ls -l /s/sftgdia/${file_name}| awk -F' ' '{print $5}'`
done

if [ "$size_file" == "$actual_size" ]
then
#echo "SFTGDIA QA, File ${file_name} loaded successfully" >> summary.txt #| mailx -s "SFTGDIA QA, File ${file_name} loaded successfully" latluri1@ford.com
mv /s/${USER}/${file_name} /s/${USER}/${file_name_renamed} || true
destination_dir=$(get_destination_dir ${file_name_renamed})
if [ -z "${destination_dir}" ]
then
destination_dir=${default_dir}
fi
sed -i "s/${file_name}/${file_name}|SUCCESS/g" summary.txt
hadoop fs -moveFromLocal -f /s/${USER}/${file_name_renamed} ${destination_dir} || true
hadoop fs -chmod 770 ${destination_dir}/${file_name_renamed}
elif [ "${k}" -eq 5 ]
then
#echo "SFTGDIA QA, Failed to load file ${file_name}" >> summary.txt #| mailx -s "SFTGDIA QA, Failed to load file ${file_name}" latluri1@ford.com
mv /s/${USER}/${file_name} /s/${USER}/failed_${file_name_renamed} || true
sed -i "s/${file_name}/${file_name}|FAILED/g" summary.txt
hadoop fs -moveFromLocal -f /s/${USER}/failed_${file_name_renamed} ${failed_file_dir} || true
hadoop fs -chmod 770 ${failed_file_dir}/failed_${file_name_renamed}
else
echo "check the code of sftgdia qa automated_file_transfer.sh Attempt:$k File:$file_name Error:$?"|mailx -s "SFTGDIA QA, check code automated_file_transfer.sh " ${mail_to}
fi
done

######################################
#dos2unix summary.txt
echo -e "Summary \n\n $(cat summary.txt)" | mailx -s "SFTGDIA QA, load report summary ${today_}" ${mail_to}
######################################
