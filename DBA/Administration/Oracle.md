# **ORACLE ARCHITECTURE**

ORACLE has two main part 
1- Instance + background processes --> Exist in RAM
2- Database ---> Physical part 


**Instance**

It is the Database brain without it no database will be open .


**Background processes**

1-SGA = Memory shared by all users , Good SGA make database faster and bad SGA slow it down
2-PGA = 
3-SMON
4-PMON


**How does a script work?**

![[STEPS.png]]

**Data Dictionary**

conatain -> META DATA :
1- table definitions
2- User priviledges
3- Object info 


**PMON**
process monitor 
clean dead sessions users 
Release lock users 
Register listener to the instance 



**SMON**
Its use for the instance recovery like right before the SHUTDOWN ABORT  
also cleans up temp segments


**DBWR**
writes dirty blocks from buffer cache into datafiles 
It is not working on commit 


**LGWR**
Writes redo from redo buffer  to Redo log On commit and also every 3 seconds 


**Checkpoints**
Update datafiles header , control files


**Archiver**
copy redo log in archivelog


# **Oracle storage Hierarchy**

![[Storage-oracle.png]]









# **Managing Database instance**
when we start the instance an initialization parameter file is read.

we have 2 types of Parameter files :
1-SPFILE: binary file , SHOULD NOT EDITED MANUALLY only can be written and read by the database server. any changes in spfile will exist after you shutdown and restart the database

spfile is the oracle  configuration brain .  it saves all systematical change.
we should have backup from spfile so when if the spfile crashed you can recover it from back up 

2-PFILE

when you are installing DBCA you use this it is also the spdile but in our understandable language . you can create your spfile from pfile .

CREATE SPFILE FROM PFILE='path/to/your/pfile.ora'

Initializing the parameter file :
1- Basic 
2- Advance

set and tune the pfile so you can have the reasonable performance from the database .

Basic parameter :
Global database name => DB_NAME , DB_DOMAIN
FAST_RECOVERY_AREA
SGA_TARGET

PARAMETERS :
static : only change in PFILE require instance restart 
dynamic : can be changed while the database is online can be altered at session and system level


session level : affect only on a user 
system level : affect entire database and all sessions 
 


Normal operation for database is :
Instance start ---> db mount ---> OPEN


opening database includes the following :
open all datafiles
open the online redo log file

if any of the rdo log files or datafiles be missed you will get error while you are starting it up!





# Data Dictionary

Data dictionary are contain metadata which are contains the names and al attributes of all objects which are existing in the database.

Database server use data dictionary to access and find all data and informations about users , objects , constraints , storage.

It is available for all users by using the sql but the SYS user own it . 

**YOU SHOULD NEVER MODIFY THE DATA DICTIONARY DIRECTLY BY USING SQL SCRIPTS.**



# Oracle Network 

Oracle network enables network from client to the server .
Oracle Net contains Listener which is responsible for coordinating between the server and external app.
common use of oracle net is allowing incoming DB connection .
for reaching to the database listener file :

```
su - grid

vi $ORACLE_HOME/network/admin/listener
```


Gateway for nonlocal users to oracle instance .

if it was necessary only if it was necessary you can manually edit it.

Oracle Net knows these following :

Hostname , Protocol , port , service name 

```

connection ----> listener check :is the sevice name valid ? --> yes --> spawn a new process to deal with the connections.
|
|
|_______listener no more deal with connection ----> check the authenticationns (usually the passwords) ----> valid?--->yes --->Session create


```

# **Administering user security**

What is database user?
ach user is an identity to a database it can Authenticate , Use objects by owner and get license.

```
APP_USER --> CONNECTING TO APP
REPORT_USER --> GET REPORTS ONLY 
DBA_USER --> MANAGING USER 
```


Each user has these following things :
1- Authentication
2-Privileges
3-Storage Quota



#### Predefined Administrative Accounts

These are managing users in oracle :

1- SYS 
Owner of data dictionary and have for using this account you should use `AS SYSDBA` .

2-SYSTEM 
Another powerful managing 

3-SYSBACKUP، SYSDG and SYSKM
each one of these users do the specific job in database 


|Privilege|Main Purpose|
|---|---|
|`SYSDBA`|Comprehensive database administration operations, including startup and shutdown|
|`SYSOPER`|Basic database administration operations with more limited access than `SYSDBA`|
|`SYSBACKUP`|Backup and recovery operations|
|`SYSDG`|Data Guard operations|
|`SYSKM`|Managing Transparent Data Encryption (TDE) key operations|


# **Tablespace**


create a tablespace 

```
create tablespace test_tblspace
DATAFILE '/u01/app/oracle/oradata/ORCL/my_tablespace01.dbf'
SIZE 100M
AUTOEXTEND ON
NEXT 10M
MAXSIZE 2G;
```

# **Managing Space**

Space is automatically manage in oracle Database server.It generate Alert about potential problem and recommends possible solutions.



#### **OMF**
It let oracle to name and save some files where oracle wants instead of specifying the location and name in the query.

without OMF :

```
CREATE TABLESPACE app_ts
DATAFILE '/u01/app/oracle/oradata/ORCL/app_ts01.dbf'
SIZE 100M;
```

with OMF :

you only specify the size 

```
CREATE TABLESPACE app_ts
DATAFILE SIZE 100M;
```


checking OMF in your database :

```
SELECT name, value
FROM v$parameter
WHERE name IN (
    'db_create_file_dest',
    'db_create_online_log_dest_1',
    'db_recovery_file_dest'
);
```

If you add a datafile to a tablespace OMF save the name and directioon by itself you only define the size of the datafile.


**Row chaining and Migration**

when a row insert if it is too large for a data block data chaining happen. Oracle can store it across multiple blocks. This is row chaining.

when an update happen or by any chance the row gets larger oracle migrate the row to new block so it can fit in it.


#### **Managing segment free spaces**

There is 2 ways for managing the free spaces:

1- MSSM
Oracle use free list to find what block is free. Free list is a list of block free spaces. It's manage manually  
**use in older databases**

2-