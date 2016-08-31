#!/bin/bash
#Author: Kiran
#Following requirements taken care in this script
#Slave should be in sync with the master before the binary logs are deleted
#If the slave is not in sync and there is no room on the disk then delete only the binary logs, already read, by MYSQL slave
#If disk space is full and you can no more delete binary logs, then send a notification to operations team.


#ConnectionResult=`mysql -h ${host} -P ${port} -u ${user} --password=${password} -e "show slave ${connection} status\G" 2>&1`
#if [ -z "`echo "${ConnectionResult}" |grep Slave_IO_State`" ]; then
#	echo -e "CRITICAL: Unable to connect to server ${host}:${port} with username '${user}' and given password"
#	exit ${STATE_CRITICAL}
. config

#STATE_CRITICAL=2
sync_Check="Slavehasreadallrelaylog"
ConnectionResult=`mysql -h ${DBHOST} -P ${DBPORT} -u ${DBUSER} --password=${DBUSERPWD} -e "show slave status\G" 2>&1`
bLogs=`mysql -h ${DBHOST} -P ${DBPORT} -u ${DBUSER} --password=${DBUSERPWD} -e "show binary logs\G" 2>&1`


check=`echo "${ConnectionResult}" |grep Slave_SQL_Running: | awk '{print $2}'`
checkio=`echo "${ConnectionResult}" |grep Slave_IO_Running: | awk '{print $2}'`
masterinfo=`echo "${ConnectionResult}" |grep  Master_Host: | awk '{print $2}'`
delayinfo=`echo "${ConnectionResult}" |grep Seconds_Behind_Master: | awk '{print $2}'`
sync=`echo "${ConnectionResult}" |grep Slave_SQL_Running_State | awk -F ';' '{print $1}' | awk -F ':' '{print $2'} | sed 's/[ ]*//g'`
bLogs=`mysql -h localhost -P 3306 -u root --password=toor -e "show binary logs\G" |grep Log_name | awk -F ':' '{print $2}' 2>&1`
#echo $bLogs
#echo $check
#echo $checkio
#echo $masterinfo
#echo $delayinfo
#echo $sync

Binary_logs(){
allblogs=`echo "${bLogs}" 
#|grep Log_name: | awk '{print $2}'`
for bnary in $allblogs
do
# echo $bnary
 res=`mysql -h ${DBHOST} -P ${DBPORT} -u ${DBUSER} --password=${DBUSERPWD} -e "PURGE BINARY LOGS TO '$bnary'"`
 echo "$bnary deleted"
#echo  $res
if [ $# -eq 0 ]
then
  echo #########################
  echo "All binaries are deleted "
fi
done
}





mail_alert(){
   cat $1 | mail -s $2 $email

}

#Main code 
#check the SqlRunningState
 if [ $check = "Yes" ]
then
 echo "Testing Requirements "
 echo "########################"
  echo "Mysql Slave is alive"
#checing the slave is not in the sync situation
 if [ $sync = $sync_Check ]
 then
      echo "Slave is not in Sync "
      echo "Deleting the binary logs"
      Binary_logs
#     echo $disk_Space
fi

disk_Space=`df -h | grep '/$'|awk '{print $5}'|tr -d '%'`
 if [ $disk_Space -ge 80 ]
 then
     echo "disk is full"
     echo "Sending Mail alert"
     mail_alert "After deleting the binaylogs, Still disk is full $df -hT" "Still disk is full "
 fi
 else
     echo "sent mail"
     mail_alert " slave is in Sync , Unable to delet the binary logs"  "slave is in sync"
 fi



