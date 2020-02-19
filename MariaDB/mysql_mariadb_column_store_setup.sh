# =============================================
# MariaDB Columnstore Setup
# =============================================

192.168.56.101  umcs1
192.168.56.102  pmcs1
192.168.56.103  pmcs2

[root@umcs1 ~]# ssh umcs1 cat ~/.ssh/id_dsa.pub >> ~/.ssh/authorized_keys
[root@umcs1 ~]# ssh pmcs1 cat ~/.ssh/id_dsa.pub >> ~/.ssh/authorized_keys
[root@umcs1 ~]# ssh pmcs2 cat ~/.ssh/id_dsa.pub >> ~/.ssh/authorized_keys
[root@umcs1 ~]# chmod 0600 ~/.ssh/authorized_keys
[root@umcs1 ~]# scp ~/.ssh/{authorized_keys,known_hosts} pmcs1:~/.ssh/
[root@umcs1 ~]# scp ~/.ssh/{authorized_keys,known_hosts} pmcs2:~/.ssh/


yum -y install boost
yum -y install expect perl perl-DBI openssl zlib file sudo libaio rsync snappy net-tools numactl-libs nmap

rpm -ivh jemalloc-3.6.0-1.el7.x86_64.rpm

# ---------------------------------------------
# Install rpm
# all nodes (PM and UM)
# ---------------------------------------------
rpm -ivh mariadb-columnstore-1.2.5-1-*.rpm
Preparing...                          ################################# [100%]
Updating / installing...
   1:mariadb-columnstore-common-1.2.5-################################# [ 10%]
   2:mariadb-columnstore-libs-1.2.5-1 ################################# [ 20%]
   3:mariadb-columnstore-client-1.2.5-################################# [ 30%]
   4:mariadb-columnstore-server-1.2.5-################################# [ 40%]
   5:mariadb-columnstore-shared-1.2.5-################################# [ 50%]
   6:mariadb-columnstore-platform-1.2.################################# [ 60%]
The next step is:

If installing on a pm1 node using non-distributed install

/usr/local/mariadb/columnstore/bin/postConfigure

If installing on a pm1 node using distributed install

/usr/local/mariadb/columnstore/bin/postConfigure -d

If installing on a non-pm1 using the non-distributed option:

/usr/local/mariadb/columnstore/bin/columnstore start


   7:mariadb-columnstore-gssapi-server################################# [ 70%]
   8:mariadb-columnstore-rocksdb-engin################################# [ 80%]
   9:mariadb-columnstore-tokudb-engine################################# [ 90%]
  10:mariadb-columnstore-storage-engin################################# [100%]

[root@umcs1 ~]# ls -alth /usr/local/mariadb/columnstore/
total 32K
drwxr-xr-x 11 root root 4.0K Nov 24 20:58 mysql
drwxr-xr-x  2 root root 8.0K Nov 24 20:58 lib
drwxr-xr-t  2 root root  253 Nov 24 20:58 etc
drwxr-xr-x  3 root root   18 Nov 24 20:58 data
drwxr-xr-t  3 root root   25 Nov 24 20:58 data1
drwxr-xr-x  2 root root   20 Nov 24 20:58 local
drwxr-xr-x  2 root root   99 Nov 24 20:58 post
drwxr-xr-x  2 root root 4.0K Nov 24 20:58 bin
-rw-r--r--  1 root root    8 Jul 18 01:49 gitversionEngine
-rw-r--r--  1 root root   24 Jul 18 01:49 releasenum
drwxr-xr-x 10 root root  144 Jul 18 01:45 .
drwxr-xr-x  3 root root   25 Jul 18 01:45 ..

# ---------------------------------------------
# postConfigure
# ---------------------------------------------
[root@umcs1 ~]# /usr/local/mariadb/columnstore/bin/postConfigure -h

This is the MariaDB ColumnStore System Configuration and Installation tool.
It will Configure the MariaDB ColumnStore System based on Operator inputs and
will perform a Package Installation of all of the Modules within the
System that is being configured.

IMPORTANT: This tool is required to run on a Performance Module #1 (pm1) Server.

Instructions:

        Press 'enter' to accept a value in (), if available or
        Enter one of the options within [], if available, or
        Enter a new value


Usage: postConfigure [-h][-c][-u][-p][-qs][-qm][-qa][-port][-i][-n][-d][-sn][-pm-ip-addrs][-um-ip-addrs][-pm-count][-um-count][-x][-xr][-numBlocksPct][-totalUmMemory]
   -h  Help
   -c  Config File to use to extract configuration data, default is Columnstore.xml.rpmsave
   -u  Upgrade, Install using the Config File from -c, default to Columnstore.xml.rpmsave
            If ssh-keys aren''t setup, you should provide passwords as command line arguments
   -p  Unix Password, used with no-prompting option
   -qs Quick Install - Single Server
   -qm Quick Install - Multi Server
   -port MariaDB ColumnStore Port Address
   -i  Non-root Install directory, Only use for non-root installs
   -n  Non-distributed install, meaning postConfigure will not install packages on remote nodes
   -d  Distributed install, meaning postConfigure will install packages on remote nodes
   -sn System Name
   -pm-ip-addrs Performance Module IP Addresses xxx.xxx.xxx.xxx,xxx.xxx.xxx.xxx
   -um-ip-addrs User Module IP Addresses xxx.xxx.xxx.xxx,xxx.xxx.xxx.xxx
   -x  Do not resolve IP Addresses from host names
   -xr Resolve host names into their reverse DNS host names. Only applied in combination with -x
   -numBlocksPct amount of physical memory to utilize for disk block caching
    (percentages of the total memory need to be stated without suffix, explcit values with suffixes M or G)
   -totalUmMemory amount of physical memory to utilize for joins, intermediate results and set operations on the UM
    (percentages of the total memory need to be stated with suffix %, explcit values with suffixes M or G)
	
# ---------------------------------------------
# postConfigure start from pmcs1 
# ---------------------------------------------
/usr/local/mariadb/columnstore/bin/postConfigure -pm-ip-addrs 192.168.56.102,192.168.56.103 -um-ip-addrs 192.168.56.101

--> if get this message:
MariaDB ColumnStore is running, can''t run postConfigure while MariaDB ColumnStore is running. Exiting..
--> execute this 
[root@pmcs1 ~]# mcsadmin shutdownsystem y
shutdownsystem   Mon Nov 25 10:57:37 2019

[root@pmcs1 ~]# /usr/local/mariadb/columnstore/bin/postConfigure -d

This is the MariaDB ColumnStore System Configuration and Installation tool.
It will Configure the MariaDB ColumnStore System and will perform a Package
Installation of all of the Servers within the System that is being configured.

IMPORTANT: This tool requires to run on the Performance Module #1

Prompting instructions:

        Press 'enter' to accept a value in (), if available or
        Enter one of the options within [], if available, or
        Enter a new value


===== Setup System Server Type Configuration =====

There are 2 options when configuring the System Server Type: single and multi

  'single'  - Single-Server install is used when there will only be 1 server configured
              on the system. It can also be used for production systems, if the plan is
              to stay single-server.

  'multi'   - Multi-Server install is used when you want to configure multiple servers now or
              in the future. With Multi-Server install, you can still configure just 1 server
              now and add on addition servers/modules in the future.

Select the type of System Server install [1=single, 2=multi] (2) > 2


===== Setup System Module Type Configuration =====

There are 2 options when configuring the System Module Type: separate and combined

  'separate' - User and Performance functionality on separate servers.

  'combined' - User and Performance functionality on the same server

Select the type of System Module Install [1=separate, 2=combined] (1) > 1

Seperate Server Installation will be performed.

NOTE: Local Query Feature allows the ability to query data from a single Performance
      Module. Check MariaDB ColumnStore Admin Guide for additional information.

Enable Local Query feature? [y,n] (n) >

NOTE: The MariaDB ColumnStore Schema Sync feature will replicate all of the
      schemas and InnoDB tables across the User Module nodes. This feature can be enabled
      or disabled, for example, if you wish to configure your own replication post installation.

MariaDB ColumnStore Schema Sync feature, do you want to enable? [y,n] (y) > n


Enter System Name (columnstore-1) > mycs-1


===== Setup Storage Configuration =====


----- Setup Performance Module DBRoot Data Storage Mount Configuration -----

There are 2 options when configuring the storage: internal or external

  'internal' -    This is specified when a local disk is used for the DBRoot storage.
                  High Availability Server Failover is not Supported in this mode

  'external' -    This is specified when the DBRoot directories are mounted.
                  High Availability Server Failover is Supported in this mode.

Select the type of Data Storage [1=internal, 2=external] (1) > 1

===== Setup Memory Configuration =====


NOTE: Setting 'NumBlocksPct' to 70%
      Setting 'TotalUmMemory' to 50%


===== Setup the Module Configuration =====


----- User Module Configuration -----

Enter number of User Modules [1,1024] (1) > 1

*** User Module #1 Configuration ***

Enter Nic Interface #1 Host Name (unassigned) > umcs1
Enter Nic Interface #1 IP Address or hostname of umcs1 (192.168.1.101) > 192.168.1.101
Enter Nic Interface #2 Host Name (unassigned) >

----- Performance Module Configuration -----

Enter number of Performance Modules [1,1024] (1) > 2

*** Parent OAM Module Performance Module #1 Configuration ***

Enter Nic Interface #1 Host Name (pmcs1) > pmcs1
Enter Nic Interface #1 IP Address or hostname of pmcs1 (192.168.1.102) > 192.168.1.102
Enter Nic Interface #2 Host Name (unassigned) >
Enter the list (Nx,Ny,Nz) or range (Nx-Nz) of DBRoot IDs assigned to module 'pm1' (1) > 1

*** Performance Module #2 Configuration ***

Enter Nic Interface #1 Host Name (unassigned) > pmcs2
Enter Nic Interface #1 IP Address or hostname of pmcs2 (192.168.1.103) > 192.168.1.103
Enter Nic Interface #2 Host Name (unassigned) >
Enter the list (Nx,Ny,Nz) or range (Nx-Nz) of DBRoot IDs assigned to module 'pm2' () > 2

Next step is to enter the password to access the other Servers.
This is either user password or you can default to using a ssh key
If using a user password, the password needs to be the same on all Servers.

Enter password, hit 'enter' to default to using a ssh key, or 'exit' >

===== System Installation =====

System Configuration is complete.
Performing System Installation.

Performing a MariaDB ColumnStore System install using RPM packages
located in the /root directory.


----- Performing Install on 'um1 / umcs1' -----

Install log file is located here: /tmp/columnstore_tmp_files/um1_rpm_install.log


----- Performing Install on 'pm2 / pmcs2' -----

Install log file is located here: /tmp/columnstore_tmp_files/pm2_rpm_install.log


MariaDB ColumnStore Package being installed, please wait ...  DONE

===== Checking MariaDB ColumnStore System Logging Functionality =====

The MariaDB ColumnStore system logging is setup and working on local server

===== MariaDB ColumnStore System Startup =====

System Configuration is complete.
Performing System Installation.

----- Starting MariaDB ColumnStore on local server -----

MariaDB ColumnStore successfully started

MariaDB ColumnStore Database Platform Starting, please wait ................ DONE

System Catalog Successfully Created

MariaDB ColumnStore Install Successfully Completed, System is Active

Enter the following command to define MariaDB ColumnStore Alias Commands

. /etc/profile.d/columnstoreAlias.sh

Enter 'mcsmysql' to access the MariaDB ColumnStore SQL console
Enter 'mcsadmin' to access the MariaDB ColumnStore Admin console

NOTE: The MariaDB ColumnStore Alias Commands are in /etc/profile.d/columnstoreAlias.sh

[root@pmcs1 ~]#

# ---------------------------------------------
# on all nodes
# ---------------------------------------------
[root@pmcs1 ~]# ssh umcs1 "chmod +x /etc/profile.d/columnstoreAlias.sh"
[root@pmcs1 ~]# ssh pmcs1 "chmod +x /etc/profile.d/columnstoreAlias.sh"
[root@pmcs1 ~]# ssh pmcs2 "chmod +x /etc/profile.d/columnstoreAlias.sh"
[root@pmcs1 ~]# ssh umcs1 "source /etc/profile.d/columnstoreAlias.sh"
[root@pmcs1 ~]# ssh pmcs1 "source /etc/profile.d/columnstoreAlias.sh"
[root@pmcs1 ~]# ssh pmcs2 "source /etc/profile.d/columnstoreAlias.sh"
# ---------------------------------------------
# check configuration
# ---------------------------------------------
[root@umcs1 ~]# mcsmysql
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 16
Server version: 10.3.16-MariaDB-log Columnstore 1.2.5-1

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.
MariaDB [(none)]> show databases;
+---------------------+
| Database            |
+---------------------+
| calpontsys          |
| columnstore_info    |
| infinidb_querystats |
| infinidb_vtable     |
| information_schema  |
| mysql               |
| performance_schema  |
| test                |
+---------------------+
8 rows in set (0.000 sec)

[root@umcs1 ~]# mcsadmin getSystemInfo

WARNING: running on non Parent OAM Module, can''t make configuration changes in this session.
         Access Console from 'pm1' if you need to make changes.

getsysteminfo   Mon Nov 25 18:13:56 2019

System mycs-1

System and Module statuses

Component     Status                       Last Status Change
------------  --------------------------   ------------------------
System        ACTIVE                       Mon Nov 25 17:51:31 2019

Module um1    ACTIVE                       Mon Nov 25 17:51:28 2019
Module pm1    ACTIVE                       Mon Nov 25 17:51:09 2019
Module pm2    ACTIVE                       Mon Nov 25 17:51:18 2019

Active Parent OAM Performance Module is 'pm1'
MariaDB ColumnStore set for Distributed Install


MariaDB ColumnStore Process statuses

Process             Module    Status            Last Status Change        Process ID
------------------  ------    ---------------   ------------------------  ----------
ProcessMonitor      um1       ACTIVE            Mon Nov 25 17:50:42 2019        3090
ServerMonitor       um1       ACTIVE            Mon Nov 25 17:51:11 2019        3706
DBRMWorkerNode      um1       ACTIVE            Mon Nov 25 17:51:11 2019        3754
ExeMgr              um1       ACTIVE            Mon Nov 25 17:51:21 2019        4808
DDLProc             um1       ACTIVE            Mon Nov 25 17:51:25 2019        4826
DMLProc             um1       ACTIVE            Mon Nov 25 17:51:30 2019        4872
mysqld              um1       ACTIVE            Mon Nov 25 17:51:20 2019        3662

ProcessMonitor      pm1       ACTIVE            Mon Nov 25 17:49:42 2019        2569
ProcessManager      pm1       ACTIVE            Mon Nov 25 17:49:48 2019        2646
DBRMControllerNode  pm1       ACTIVE            Mon Nov 25 17:51:03 2019        3997
ServerMonitor       pm1       ACTIVE            Mon Nov 25 17:51:05 2019        4019
DBRMWorkerNode      pm1       ACTIVE            Mon Nov 25 17:51:05 2019        4062
PrimProc            pm1       ACTIVE            Mon Nov 25 17:51:09 2019        4205
WriteEngineServer   pm1       ACTIVE            Mon Nov 25 17:51:10 2019        4268

ProcessMonitor      pm2       ACTIVE            Mon Nov 25 17:50:56 2019        2548
ProcessManager      pm2       HOT_STANDBY       Mon Nov 25 17:50:57 2019        2592
DBRMControllerNode  pm2       COLD_STANDBY      Mon Nov 25 17:51:11 2019
ServerMonitor       pm2       ACTIVE            Mon Nov 25 17:51:14 2019        2625
DBRMWorkerNode      pm2       ACTIVE            Mon Nov 25 17:51:14 2019        2641
PrimProc            pm2       ACTIVE            Mon Nov 25 17:51:18 2019        2658
WriteEngineServer   pm2       ACTIVE            Mon Nov 25 17:51:19 2019        2668

Active Alarm Counts: Critical = 0, Major = 0, Minor = 0, Warning = 0, Info = 0
[root@umcs1 ~]#

MariaDB [(none)]>



/etc/profile.d/columnstoreAlias.sh



