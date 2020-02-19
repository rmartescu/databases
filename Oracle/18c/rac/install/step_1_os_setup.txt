# ----------------------------------------------------------------------------
# /etc/hosts
# ----------------------------------------------------------------------------
192.168.0.10  oradns
192.168.0.41  ora18rac1.mydomain.net      ora18rac1
192.168.0.42  ora18rac2.mydomain.net      ora18rac2
192.168.0.43  ora18rac1-vip.mydomain.net  ora18rac1-vip
192.168.0.44  ora18rac2-vip.mydomain.net  ora18rac2-vip
192.168.56.41 ora18rac1-priv
192.168.56.42 ora18rac2-priv

192.168.0.45  ora18rac-scan.mydomain.net  ora18rac-scan
192.168.0.46  ora18rac-scan.mydomain.net  ora18rac-scan
192.168.0.47  ora18rac-scan.mydomain.net  ora18rac-scan
# ----------------------------------------------------------------------------
# ASM Disk Configuration Pre-requirements
# ----------------------------------------------------------------------------
VOLACFS01  /dev/oracleasm/volacfs01 - 20G
VOLDATA01  /dev/oracleasm/voldata01 - 20G
VOLGIMR01  /dev/oracleasm/volgimr01 - 30G (mandatory)
VOLLOG01   /dev/oracleasm/vollog01  - 20G
VOLOCR01   /dev/oracleasm/volocr01  - 10G (mandatory)

# ----------------------------------------------------------------------------
# Install rpm
# ----------------------------------------------------------------------------
yum -y install oracle-database-preinstall-18c
yum -y install net-tools
yum -y install bind-utils

# ----------------------------------------------------------------------------
# /etc/resolv.conf
# ----------------------------------------------------------------------------
search mydomain.net
nameserver 192.168.0.10
# ----------------------------------------------------------------------------
# Configure SCAN DNS Lookup
# ----------------------------------------------------------------------------
[root@ora18rac1 ~]# nslookup ora18rac-scan
Server:         192.168.0.10
Address:        192.168.0.10#53

Name:   ora18rac-scan.mydomain.net
Address: 192.168.0.45
Name:   ora18rac-scan.mydomain.net
Address: 192.168.0.47
Name:   ora18rac-scan.mydomain.net
Address: 192.168.0.46
# ----------------------------------------------------------------------------
# Disable firewall
# ----------------------------------------------------------------------------
systemctl stop firewalld
systemctl disable firewalld
# ----------------------------------------------------------------------------
# Configure SELINUX
# /etc/selinux/config
# ----------------------------------------------------------------------------
SELINUX=disabled
# ----------------------------------------------------------------------------
# /etc/ntpd.conf
# ----------------------------------------------------------------------------
driftfile /var/lib/ntp/drift
logfile /var/log/ntp.log

server ntp.yahoo.fr prefer
server 0.fr.pool.ntp.org 
server 1.fr.pool.ntp.org
server 2.fr.pool.ntp.org
server 3.fr.pool.ntp.org

# ----------------------------------------------------------------------------
ntpdate fr.pool.ntp.org
watch ntpq -p

# ----------------------------------------------------------------------------
# /etc/ntpd.conf
# add: -x 
# ----------------------------------------------------------------------------
[root@ora18rac1 ~]# cat /etc/sysconfig/ntpd
# Command line options for ntpd
OPTIONS="-x -g"

# ----------------------------------------------------------------------------
# Create Users
# ----------------------------------------------------------------------------
userdel oracle
userdel grid

groupdel oinstall
groupdel dba
groupdel oper
groupdel backupdba
groupdel dgdba
groupdel kmdba
groupdel asmdba
groupdel asmoper
groupdel asmadmin
groupdel racdba

groupadd -g 54321 oinstall
groupadd -g 54322 dba
groupadd -g 54323 oper
groupadd -g 54324 backupdba
groupadd -g 54325 dgdba
groupadd -g 54326 kmdba
groupadd -g 54327 asmdba
groupadd -g 54328 asmoper
groupadd -g 54329 asmadmin
groupadd -g 54330 racdba


useradd -u 54321 -g oinstall -G oper,dba,asmdba,backupdba,dgdba,kmdba,racdba oracle
useradd -u 54322 -g oinstall -G dba,asmdba,asmoper,asmadmin,racdba grid

$ id oracle
uid=54321(oracle) gid=54321(oinstall) groups=54321(oinstall),54322(dba),
54323(oper),54324(backupdba),54325(dgdba),54326(kmdba),54327(asmdba),
54330(racdba)
$ id grid
uid=54331(grid) gid=54321(oinstall) groups=54321(oinstall),54322(dba),
54327(asmdba),54328(asmoper),54329(asmadmin),54330(racdba)

# ----------------------------------------------------------------------------
# Setup ssh for root,grid, oracle
# ----------------------------------------------------------------------------
su - 
ssh-keygen -t dsa

ssh ora18rac1 cat ~/.ssh/id_dsa.pub >> ~/.ssh/authorized_keys
ssh ora18rac2 cat ~/.ssh/id_dsa.pub >> ~/.ssh/authorized_keys
ssh ora18rac1-priv cat ~/.ssh/id_dsa.pub >> ~/.ssh/authorized_keys
ssh ora18rac2-priv cat ~/.ssh/id_dsa.pub >> ~/.ssh/authorized_keys
chmod 0600 ~/.ssh/authorized_keys
scp ~/.ssh/{known_hosts,authorized_keys} ora18rac2:~/.ssh/

ssh ora18rac1 date
ssh ora18rac2 date
ssh ora18rac1-priv date
ssh ora18rac2-priv date


# ----------------------------------------------------------------------------
# Disable avahi deamon
# ----------------------------------------------------------------------------
systemctl stop avahi-dnsconfd
systemctl stop avahi-daemon
systemctl disable avahi-dnsconfd
systemctl disable avahi-daemon
systemctl stop cronyd
systemctl disable cronyd

# ----------------------------------------------------------------------------
# Configure 
# /etc/security/limits.d/oracle-database-preinstall-18c.conf
# ----------------------------------------------------------------------------
sed -i '/^$/d' /etc/security/limits.d/oracle-database-preinstall-18c.conf
sed -i '/^#/d' /etc/security/limits.d/oracle-database-preinstall-18c.conf

sed -e 's/^oracle/grid/g' /etc/security/limits.d/oracle-database-preinstall-18c.conf >> /etc/security/limits.d/oracle-database-preinstall-18c.conf
scp /etc/security/limits.d/oracle-database-preinstall-18c.conf ora18rac2:/etc/security/limits.d/oracle-database-preinstall-18c.conf

# ----------------------------------------------------------------------------
# /etc/pam.d/login
# add this line
# ----------------------------------------------------------------------------
session    required     pam_limits.so

echo "session    required     pam_limits.so" >> /etc/pam.d/login
scp /etc/pam.d/login ora18rac2:/etc/pam.d/login

# ----------------------------------------------------------------------------
# /etc/profile
# add these lines
# ----------------------------------------------------------------------------
if [ $USER = "oracle" ] || [ $USER = "grid" ]; then
    if [ $SHELL = "/bin/ksh" ]; then
        ulimit -p 16384 ulimit -n 65536
    else
        ulimit -u 16384 -n 65536
    fi
    umask 022
fi

scp /etc/profile ora18rac2:/etc/profile
# ----------------------------------------------------------------------------
# Create Oracle Directories
# ----------------------------------------------------------------------------
mkdir -p /u01/adm
mkdir -p /u01/app/grid
mkdir -p /u01/app/18.0.0/grid
mkdir -p /u01/app/oracle/product/18.0.0/db
chown -R grid:oinstall /u01/app
chown -R oracle:oinstall /u01/app/oracle
chown -R grid:oinstall /u01/adm
chmod -R 775 /u01/app
chmod -R 775 /u01/adm

# ----------------------------------------------------------------------------
# grid: configure .bash_profile
# ----------------------------------------------------------------------------
BASE_PATH=/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/home/grid/.local/bin:/home/grid/bin

export TMP=/tmp
export TMPDIR=$TMP
export ORACLE_HOSTNAME=ora18rac1
export ORACLE_BASE=/u01/app/grid
export ORACLE_HOME=/u01/app/18.0.0/grid
export ORACLE_SID=+ASM1
export ORACLE_TERM=xterm
export PATH=$ORACLE_HOME/bin:$BASE_PATH
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib
export CLASSPATH=$ORACLE_HOME/JRE:$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib
export PS1="[\u@\h \W:$ORACLE_SID]\$ "

if [ -t 0 ]; then
   stty intr ^C
fi
umask 022

# ----------------------------------------------------------------------------
# oracle: configure .bash_profile
# ----------------------------------------------------------------------------
BASE_PATH=/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/home/oracle/.local/bin:/home/oracle/bin

export TMP=/tmp
export TMPDIR=$TMP
export ORACLE_HOSTNAME=ora18rac1
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=/u01/app/oracle/product/18.0.0/db
export ORACLE_SID=VMSCDB1
export ORACLE_TERM=xterm
export BASE_PATH=/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/home/grid/.local/bin:/home/grid/bin
export PATH=$ORACLE_HOME/bin:$BASE_PATH
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib
export CLASSPATH=$ORACLE_HOME/JRE:$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib
export PS1="[\u@\h \W:$ORACLE_SID]\$ "

if [ -t 0 ]; then
   stty intr ^C
fi
umask 022

# ----------------------------------------------------------------------------
# Partition asm disk
# ----------------------------------------------------------------------------
fdisk /dev/sdb
fdisk /dev/sdc
fdisk /dev/sdd
fdisk /dev/sde
fdisk /dev/sdf

partprobe /dev/sdb1
partprobe /dev/sdc1
partprobe /dev/sdd1
partprobe /dev/sde1
partprobe /dev/sdf1

# ----------------------------------------------------------------------------
# /etc/scsi_id.config
# add this line
# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------
options=-g

scp /etc/scsi_id.config ora18rac2:/etc/scsi_id.config

# ----------------------------------------------------------------------------
# Verifying the Disk I/O Scheduler
# Target: all nodes
# User: root
# ----------------------------------------------------------------------------
cat /sys/block/${ASM_DISK}/queue/scheduler
noop [deadline] cfq

vi /etc/udev/rules.d/60-oracle-schedulers.rules
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0",ATTR{queue/scheduler}="deadline"

scp /etc/udev/rules.d/60-oracle-schedulers.rules ora18rac2:/etc/udev/rules.d/60-oracle-schedulers.rules

udevadm control --reload-rules;udevadm trigger --type=devices --action=change;

# ----------------------------------------------------------------------------
# Configure udev rules
# /etc/udev/rules.d/99-oracleasm.rules
# ----------------------------------------------------------------------------
[root@ora18rac1 ~]# /lib/udev/scsi_id -g -u -d /dev/sdb1
1ATA_VBOX_HARDDISK_VB88533d5e-a7697ef8
[root@ora18rac1 ~]# /lib/udev/scsi_id -g -u -d /dev/sdc1
1ATA_VBOX_HARDDISK_VBb822d282-1379a93d
[root@ora18rac1 ~]# /lib/udev/scsi_id -g -u -d /dev/sdd1
1ATA_VBOX_HARDDISK_VB25a765c3-04a58799
[root@ora18rac1 ~]# /lib/udev/scsi_id -g -u -d /dev/sde1
1ATA_VBOX_HARDDISK_VBc8add445-d0b40fa4
[root@ora18rac1 ~]# /lib/udev/scsi_id -g -u -d /dev/sdf1
1ATA_VBOX_HARDDISK_VB6c720973-2b18b07a

>/etc/udev/rules.d/99-oracleasm.rules

ACTION=="add|change", KERNEL=="sdb", ENV{DEVTYPE}=="disk", SUBSYSTEM=="block", PROGRAM=="/usr/lib/udev/scsi_id -g -u -d $devnode", RESULT=="1ATA_VBOX_HARDDISK_VB88533d5e-a7697ef8", RUN+="/bin/sh -c '/usr/bin/mkdir /dev/oracleasm; mknod /dev/oracleasm/volocr01 b $major $minor; chown grid:asmadmin /dev/oracleasm/volocr01; chmod 0660 /dev/oracleasm/volocr01'"
ACTION=="add|change", KERNEL=="sdc", ENV{DEVTYPE}=="disk", SUBSYSTEM=="block", PROGRAM=="/usr/lib/udev/scsi_id -g -u -d $devnode", RESULT=="1ATA_VBOX_HARDDISK_VBb822d282-1379a93d", RUN+="/bin/sh -c '/usr/bin/mkdir /dev/oracleasm; mknod /dev/oracleasm/volgimr01 b $major $minor; chown grid:asmadmin /dev/oracleasm/volgimr01; chmod 0660 /dev/oracleasm/volgimr01'"
ACTION=="add|change", KERNEL=="sdd", ENV{DEVTYPE}=="disk", SUBSYSTEM=="block", PROGRAM=="/usr/lib/udev/scsi_id -g -u -d $devnode", RESULT=="1ATA_VBOX_HARDDISK_VB25a765c3-04a58799", RUN+="/bin/sh -c '/usr/bin/mkdir /dev/oracleasm; mknod /dev/oracleasm/voldata01 b $major $minor; chown grid:asmadmin /dev/oracleasm/voldata01; chmod 0660 /dev/oracleasm/voldata01'"
ACTION=="add|change", KERNEL=="sde", ENV{DEVTYPE}=="disk", SUBSYSTEM=="block", PROGRAM=="/usr/lib/udev/scsi_id -g -u -d $devnode", RESULT=="1ATA_VBOX_HARDDISK_VBc8add445-d0b40fa4", RUN+="/bin/sh -c '/usr/bin/mkdir /dev/oracleasm; mknod /dev/oracleasm/vollog01 b $major $minor; chown grid:asmadmin /dev/oracleasm/vollog01; chmod 0660 /dev/oracleasm/vollog01'"
ACTION=="add|change", KERNEL=="sdf", ENV{DEVTYPE}=="disk", SUBSYSTEM=="block", PROGRAM=="/usr/lib/udev/scsi_id -g -u -d $devnode", RESULT=="1ATA_VBOX_HARDDISK_VB6c720973-2b18b07a", RUN+="/bin/sh -c '/usr/bin/mkdir /dev/oracleasm; mknod /dev/oracleasm/volacfs01 b $major $minor; chown grid:asmadmin /dev/oracleasm/volacfs01; chmod 0660 /dev/oracleasm/volacfs01'"


scp /etc/udev/rules.d/99-oracleasm.rules ora18rac2:/etc/udev/rules.d/99-oracleasm.rules

udevadm control --reload-rules;udevadm trigger --type=devices --action=change; ls -alth /dev/oracleasm

[root@ora18rac1 ~]# ls -alth /dev/oracleasm/ | sort
brw-rw----  1 grid asmadmin 8, 16 Jan  5 10:30 volocr01
brw-rw----  1 grid asmadmin 8, 32 Jan  5 10:30 volgimr01
brw-rw----  1 grid asmadmin 8, 48 Jan  5 10:30 voldata01
brw-rw----  1 grid asmadmin 8, 64 Jan  5 10:30 vollog01
brw-rw----  1 grid asmadmin 8, 80 Jan  5 10:30 volacfs01


# ----------------------------------------------------------------------------
# Disable Transparent HugePages
# ----------------------------------------------------------------------------
[root@ora18rac1 ~]# cat /sys/kernel/mm/transparent_hugepage/enabled
always madvise [never] --> THP Disabled

[root@ora18rac1 ~]# uname -a
Linux ora18rac1 4.14.35-1902.8.4.el7uek.x86_64 #2 SMP Mon Dec 9 11:39:31 PST 2019 x86_64 x86_64 x86_64 GNU/Linux
[root@ora18rac1 ~]# grep -i CONFIG_TRANSPARENT_HUGEPAGE /boot/config-4.14.35-1902.8.4.el7uek.x86_64
CONFIG_TRANSPARENT_HUGEPAGE=y
CONFIG_TRANSPARENT_HUGEPAGE_ALWAYS=y
# CONFIG_TRANSPARENT_HUGEPAGE_MADVISE is not set

If NOT Disable, modify /etc/default/grub:
-> Add transparent_hugepage=never

[root@ora18rac1 ~]# cat /etc/default/grub
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR="$(sed 's, release .*$,,g' /etc/system-release)"
GRUB_DEFAULT=saved
GRUB_DISABLE_SUBMENU=true
GRUB_TERMINAL_OUTPUT="console"
GRUB_CMDLINE_LINUX="rd.lvm.lv=VgSys/LvRoot rd.lvm.lv=VgSys/LvSwap1 rhgb quiet numa=off transparent_hugepage=never"
GRUB_DISABLE_RECOVERY="true"

-> Run the grub2–mkconfig command to regenerate the grub.cfg file
grub2-mkconfig -o /boot/grub2/grub.cfg

-> Reboot the server

# ----------------------------------------------------------------------------
# Configure HugePage
# ----------------------------------------------------------------------------
# During Oracle Grid Infrastructure installation, the Grid Infrastructure Management Repository
# (GIMR) is configured to use HugePages. Because the Grid Infrastructure
# Management Repository database starts before all other databases installed on the
# cluster, if the space allocated to HugePages is insufficient, then the System Global
# Area (SGA) of one or more databases may be mapped to regular pages, instead of
# Hugepages, which can adversely affect performance. Configure the HugePages memory
# allocation to a size large enough to accommodate the sum of the SGA sizes of all
# the databases you intend to install on the cluster, as well as the Grid Infrastructure
# Management Repository

# The GIMR SGA occupies up to 1 GB of HugePages memory
[root@ora18rac1 ~]# grep Huge /proc/meminfo
AnonHugePages:         0 kB
ShmemHugePages:        0 kB
HugePages_Total:       0
HugePages_Free:        0
HugePages_Rsvd:        0
HugePages_Surp:        0
Hugepagesize:       2048 kB

-> to configure HugePages_Total = (1024*1024)/2048 = 512
-> add /etc/sysctl.conf

# GIMR HugePage 1G
vm.nr_hugepages=512

[root@ora18rac1 ~]# grep Huge /proc/meminfo
AnonHugePages:         0 kB
ShmemHugePages:        0 kB
HugePages_Total:     512
HugePages_Free:      512
HugePages_Rsvd:        0
HugePages_Surp:        0
Hugepagesize:       2048 kB

[root@ora18rac2 ~]# grep Huge /proc/meminfo
AnonHugePages:         0 kB
ShmemHugePages:        0 kB
HugePages_Total:     512
HugePages_Free:      512
HugePages_Rsvd:        0
HugePages_Surp:        0
Hugepagesize:       2048 kB


