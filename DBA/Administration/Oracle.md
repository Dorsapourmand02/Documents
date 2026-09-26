`# **ORACLE ARCHITECTURE**

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

