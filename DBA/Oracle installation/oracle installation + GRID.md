
Here is the step-by-step documentation of all the actions taken so far:

  

### **Oracle Grid & Database 19c Pre-installation Steps (Oracle Linux 7.8)**

#### **1. VMware Infrastructure Setup**

- Created a Virtual Machine running **Oracle Linux 7.8 64-bit**.
    
      
    
- Allocated System Resources:
    
      
    - **OS Disk:** 100 GB (SCSI)
        
          
        
    - **ASM Disks:** 20 GB
        
          
        
    - **ISO Image:** Attached `OracleLinux-R7-U8-Server-x86_64-dvd-2`.
        
          
        

#### **2. Local Yum Repository Configuration**

To bypass Oracle download/network restrictions (HTTP 403) and install prerequisite packages offline:

  

1. **Mounted the Oracle Linux Installation DVD:**
    Here if you couldn't mount your iso you should restart the machine.
      
    
    Bash
    
    ```
    mkdir -p /media/cdrom
    mount /dev/cdrom /media/cdrom
    ```
    
2. **Backed up existing repository configurations:**
    
      
    
    Bash
    
    ```
    cd /etc/yum.repos.d/
    mkdir repo_backup
    mv *.repo repo_backup/
    ```
    
3. **Created a Local DVD Repository file (`/etc/yum.repos.d/local.repo`):**
    
      
    
    Bash
    
    ```
    cat << 'EOF' > /etc/yum.repos.d/local.repo
    [local-media]
    name=Oracle Linux Local DVD
    baseurl=file:///media/cdrom
    gpgcheck=0
    enabled=1
    EOF
    ```
    
4. **Cleared Cache and Verified Local Repository:**
    
      
    
    Bash
    
    ```
    yum clean all && yum repolist
    ```
    
    _Verified: 5,211 packages available locally._
    
      
    

#### **3. Installing Oracle 19c Pre-installation Package**

Automated kernel parameter tuning and prerequisite package installation using the local media:

  

Bash

```
yum install -y oracle-database-preinstall-19c
```

To verify the installation step was successful, check that `Complete!` appears at the end of the `yum` command output.


#### **4. Production User & Group Creation (Separation of Duties)**

Created dedicated ASM administration groups and created/configured the `grid` and `oracle` OS accounts:

Bash

```
# Create dedicated ASM groups
groupadd -g 54327 asmadmin
groupadd -g 54328 asmdba
groupadd -g 54329 asmoper

# Modify existing oracle user primary & secondary groups
usermod -g oinstall -G dba,asmdba,oper oracle

# Create dedicated grid user
useradd -u 54331 -g oinstall -G asmadmin,asmdba,asmoper,dba grid

# Set passwords
passwd oracle
passwd grid
```

#### **5. OFA Directory Structure Setup**

Created directory trees for Grid Infrastructure and Oracle Database Homes, applying strict ownership rules:

Bash

```
# Create directories
mkdir -p /u01/app/19.3.0/grid
mkdir -p /u01/app/oracle/product/19.3.0/dbhome_1
mkdir -p /u01/app/grid
mkdir -p /u01/app/oracle

# Set permissions and ownership
chown -R grid:oinstall /u01/app/19.3.0/grid
chown -R grid:oinstall /u01/app/grid
chown -R oracle:oinstall /u01/app/oracle
chown -R oracle:oinstall /u01/app/oracle/product/19.3.0/dbhome_1

chmod -R 775 /u01
```
#### **6. ASM Partitioning Configuration**

Partitioned the dedicated 20 GB SCSI disk for ASM storage using `fdisk`:

Bash

```
fdisk /dev/sdb
# Command sequence: n -> p -> 1 -> Enter -> Enter -> w
```

_Verified output using `lsblk /dev/sdb`: `/dev/sdb1` (20 GB partition created)_

#### **7. Persistent Device Naming using Udev Rules**

Configured Udev rules to ensure proper ownership (`grid:asmadmin`) and persistence across system reboots for the ASM storage partition:

Bash

```
# Create Udev rule file
cat << 'EOF' > /etc/udev/rules.d/99-oracle-asmdevices.rules
KERNEL=="sdb1", OWNER="grid", GROUP="asmadmin", MODE="0660"
EOF

# Reload and apply rules
udevadm control --reload-rules
udevadm trigger
```

_Verification: Executed `ls -l /dev/sdb1` to confirm permissions `brw-rw---- grid asmadmin`_


#### **8. Grid Infrastructure Media Transfer & Unzip Preparation**

Transferred the Oracle Grid Infrastructure 19c image zip file (`LINUX.X64_193000_grid_home.zip`) directly into the target `GRID_HOME` directory (`/home/grid/`) via SCP

```
scp "C:\Users\mohaymen\Desktop\Books\Documents\Arbeit\Installation files\LINUX.X64_193000_grid_home.zip" root@192.168.76.132:/home/grid/
```


#### **8. Grid Infrastructure Image Extraction**

Extracted the Grid Infrastructure 19c image zip directly into the `GRID_HOME` directory using the `grid` operating system user:

Bash

```
# Set ownership and navigate to GRID_HOME
chown grid:oinstall /u01/app/19.3.0/grid/LINUX.X64_193000_grid_home.zip
su - grid
cd /u01/app/19.3.0/grid/

# Perform silent extraction
unzip -q LINUX.X64_193000_grid_home.zip
```



#### **9. Environment Variables Configuration (`grid` user)**

Configured the Grid Infrastructure environment variables within `~/.bash_profile` for the `grid` user:

Bash

```
vi ~/.bash_profile 

# Oracle Grid Infrastructure Environment
export ORACLE_SID=+ASM
export ORACLE_BASE=/u01/app/grid
export ORACLE_HOME=/u01/app/19.3.0/grid
export PATH=$ORACLE_HOME/bin:$PATH
EOF

source ~/.bash_profile
```


#### **10.Installaion window for Grid steps**

![[msg68198516-1775.jpg]]![[msg68198516-1776.jpg]]![[msg68198516-1777.jpg]]![[msg68198516-1778.jpg]]![[msg68198516-1779.jpg]]![[msg68198516-1780.jpg]]![[msg68198516-1781.jpg]]




here maybe you have the package warning solve it base on the following code

```
log in with root 

export CVUQDISK_GRP=oinstall

cd /u01/app/19.3.0/grid/cv/rpm/
rpm -ivh cvuqdisk-1.0.10-1.rpm

check :
rpm -qa | grep cvuqdisk
```

also maybe listener issue

```
the error : 

CRS-5014: Agent "ORAAGENT" timed out starting process "/u01/app/19.3.0/grid/bin/lsnrctl" for action "start": details at "(:CLSN00009:)" in "/u01/app/grid/diag/crs/oraclehost/crs/trace/ohasd_oraagent_grid.trc"
CRS-2674: Start of 'ora.LISTENER.lsnr' on 'oraclehost' failed'
[main] [ 2026-09-08 15:20:03.071 IRDT ] [CRSResourceImpl.start:1042]  Process error message: PRCR-1079 : Failed to start resource ora.LISTENER.lsnr
[main] [ 2026-09-08 15:20:03.071 IRDT ] [CRSResourceImpl.start:1042]  Process error message: LSNRCTL for Linux: Version 19.0.0.0.0 - Production on 08-SEP-2026 15:14:30
[main] [ 2026-09-08 15:20:03.071 IRDT ] [CRSResourceImpl.start:1042]  Process error message: Copyright (c) 1991, 2019, Oracle.  All rights reserved.
[main] [ 2026-09-08 15:20:03.071 IRDT ] [CRSResourceImpl.start:1042]  Process error message: Starting /u01/app/19.3.0/grid/bin/tnslsnr: please wait...
[main] [ 2026-09-08 15:20:03.071 IRDT ] [CRSResourceImpl.start:1042]  Process error message: CRS-5014: Agent "ORAAGENT" timed out starting process "/u01/app/19.3.0/grid/bin/lsnrctl" for action "start": details at "(:CLSN00009:)" in "/u01/app/grid/diag/crs/oraclehost/crs/trace/ohasd_oraagent_grid.trc"
[main] [ 2026-09-08 15:20:03.071 IRDT ] [CRSResourceImpl.start:1042]  Process error message: CRS-2674: Start of 'ora.LISTENER.lsnr' on 'oraclehost' failed
[main] [ 2026-09-08 15:20:03.071 IRDT ] [ConfigureListener.startOrStopListener:1416]  PRCR-1079 : Failed to start resource ora.LISTENER.lsnr
LSNRCTL for Linux: Version 19.0.0.0.0 - Production on 08-SEP-2026 15:14:30
Copyright (c) 1991, 2019, Oracle.  All rights reserved.
Starting /u01/app/19.3.0/grid/bin/tnslsnr: please wait...
CRS-5014: Agent "ORAAGENT" timed out starting process "/u01/app/19.3.0/grid/bin/lsnrctl" for action "start": details at "(:CLSN00009:)" in "/u01/app/grid/diag/crs/oraclehost/crs/trace/ohasd_oraagent_grid.trc"
CRS-2674: Start of 'ora.LISTENER.lsnr' on 'oraclehost' failed
PRCR-1079 : Failed to start resource ora.LISTENER.lsnr
LSNRCTL for Linux: Version 19.0.0.0.0 - Production on 08-SEP-2026 15:14:30
Copyright (c) 1991, 2019, Oracle.  All rights reserved.
Starting /u01/app/19.3.0/grid/bin/tnslsnr: please wait...
CRS-5014: Agent "ORAAGENT" timed out starting process "/u01/app/19.3.0/grid/bin/lsnrctl" for action "start": details at "(:CLSN00009:)" in "/u01/app/grid/diag/crs/oraclehost/crs/trace/ohasd_oraagent_grid.trc"
CRS-2674: Start of 'ora.LISTENER.lsnr' on 'oraclehost' failed
        at oracle.cluster.impl.common.SoftwareModuleImpl.start(SoftwareModuleImpl.java:598)
        at oracle.sysman.assistants.util.hasi.HAListenerUtils.startListener(HAListenerUtils.java:293)
        at oracle.net.ca.ConfigureListener.startListener(ConfigureListener.java:1796)
        at oracle.net.ca.ConfigureListener.startOrStopListener(ConfigureListener.java:1410)
        at oracle.net.ca.ConfigureListener.typicalConfigure(ConfigureListener.java:369)
        at oracle.net.ca.SilentConfigure.performSilentConfigure(SilentConfigure.java:212)
        at oracle.net.ca.InitialSetup.<init>(NetCA.java:4325)
        at oracle.net.ca.NetCA.main(NetCA.java:460)
Caused by: PRCR-1079 : Failed to start resource ora.LISTENER.lsnr
LSNRCTL for Linux: Version 19.0.0.0.0 - Production on 08-SEP-2026 15:14:30
Copyright (c) 1991, 2019, Oracle.  All rights reserved.
Starting /u01/app/19.3.0/grid/bin/tnslsnr: please wait...
CRS-5014: Agent "ORAAGENT" timed out starting process "/u01/app/19.3.0/grid/bin/lsnrctl" for action "start": details at "(:CLSN00009:)" in "/u01/app/grid/diag/crs/oraclehost/crs/trace/ohasd_oraagent_grid.trc"
CRS-2674: Start of 'ora.LISTENER.lsnr' on 'oraclehost' failed
        at oracle.cluster.impl.crs.cops.CRSNative.genericStartResource(CRSNative.java:581)
        at oracle.cluster.impl.crs.cops.EntityOperations.startResource(EntityOperations.java:751)
        at oracle.cluster.impl.crs.CRSResourceImpl.start(CRSResourceImpl.java:1012)
        at oracle.cluster.impl.crs.CRSResourceImpl.start(CRSResourceImpl.java:987)
        at oracle.cluster.impl.crs.CRSResourceImpl.start(CRSResourceImpl.java:975)
        at oracle.cluster.impl.common.SoftwareModuleImpl.start(SoftwareModuleImpl.java:589)
        ... 7 more
Caused by: LSNRCTL for Linux: Version 19.0.0.0.0 - Production on 08-SEP-2026 15:14:30
Copyright (c) 1991, 2019, Oracle.  All rights reserved.
Starting /u01/app/19.3.0/grid/bin/tnslsnr: please wait...
CRS-5014: Agent "ORAAGENT" timed out starting process "/u01/app/19.3.0/grid/bin/lsnrctl" for action "start": details at "(:CLSN00009:)" in "/u01/app/grid/diag/crs/oraclehost/crs/trace/ohasd_oraagent_grid.trc"
CRS-2674: Start of 'ora.LISTENER.lsnr' on 'oraclehost' failed
        at oracle.cluster.impl.crs.cops.CRSNativeResult.createException(CRSNativeResult.java:641)
        at oracle.cluster.impl.crs.cops.CRSNative.doStartResource(Native Method)
        at oracle.cluster.impl.crs.cops.CRSNative.genericStartResource(CRSNative.java:575)

```



```
with root :
cat /etc/hosts

127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

your.ip.add.ress  oraclehost.localdomain oraclehost

sith grid:

lsnrctl start

with root: 
/u01/app/19.3.0/grid/root.sh

```


#### **11.oracle app Infrastructure Media Transfer & Unzip Preparation **

```
scp "C:\Users\mohaymen\Desktop\Books\Documents\Arbeit\Installation files\LINUX.X64_193000_db_home.zip" root@192.168.76.132:/home/oracle/


unzip LINUX.X64_193000_db_home.zip   -d  /u01/app/oracle/product/19.3.0/dbhome_1/

```

#### **12.Set bash_profile for oracle user

```
vi ~/.bash_profile

# .bash_profile for oracle user

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
        . ~/.bashrc
fi

# User specific environment and startup programs
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=$ORACLE_BASE/product/19.3.0/dbhome_1
export ORACLE_SID=orcl
export PATH=$PATH:$HOME/bin:$ORACLE_HOME/bin

export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib
export CLASSPATH=$ORACLE_HOME/JRE:$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib


```
#### **13.Start installation(Interactive mode)**

```
cd $ORACLE_HOME


./runInstaller

```


![[msg68198516-1798 1.jpg]]![[photo1788869647.jpeg]]![[photo1788869647 (1).jpeg]]![[photo1788869647 (2).jpeg]]![[photo1788869647 (3).jpeg]]


#### **12.Database installtion(Interactivemode)



```
dbca
```


![[photo1788866887.jpeg]]![[photo1788866887 (1).jpeg]]![[photo1788866887 (2).jpeg]]![[photo1788866887 (3).jpeg]]![[photo1788866887 (4).jpeg]]![[photo1788866887 (5).jpeg]]![[photo1788866887 (6).jpeg]]![[photo1788866887 (7).jpeg]]![[photo1788866887 (8).jpeg]]