# MysqlSlave 


How its work
-----------------

Script will check following requirements

1)Mysql Slave server should be active and run
2)Check whether slave is in sync or not, if not it will delete the binary logs
If these requirements doesn't satisfy then it will sent mail.

After deleting the binary logs ,it will check the diskspace , if it is still more than 80% then it will sent mail.


Requiremenst to run the script:
------------------------------------
1)Specify the creds in config file.
