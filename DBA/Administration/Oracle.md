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



