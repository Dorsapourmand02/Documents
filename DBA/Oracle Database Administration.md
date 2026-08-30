**Oracle database Architecture**

Oracle has 3 major structures :
1-Memory Structures 
2-Process structures 
3-Storage structures

Basic oracle database system contains => 1-Database 2-Instance

Database consist 2 part => 1- Physical structures 2- Logical structures 
because these two are separated managing one doesn't effect another.

Instance also consist 2 parts => 1-Memory structures 2-Background processes
Every time an instance is started a shared memory area call SGA(System global area) and background processes so they will be start too.

**Mounting database**
After a database instance start to work , the oracle software associate instance with a special oracle database.After that database is ready to use by authorized user.

For each Database we will have a separate instance . the instance can not be shared so if we have multiple databases which are connected to a same server there would be an instance for each database.

**SGA & PGA** 
SGA containing information and data for one oracle database instance.it is a shared memory.
PGA contain data and control information for a server or background processes . it is a non-shared memory.

SGA contains these following structures:
1-Sharedpool: contains any data which can be shared between users.
2-Data buffer: Caches block of data retrieved from data.
3-Redo log buffer : which use for instance recovery . Caches information till it ca be written on the redo log files stored in the disk.

The simplest way for managing memory is allow database do it automatically for you.

Shared pool contains: 
library cache -> sql , pl-sql
Data dictionary 
server result


**Data Dictionary** 
Data dictionary is collection of database tables and views containing reference , information about database , structures and users.

there are 2 places which are holding data dictionaries :1-Data dictionary cache 2-Library cache

Oracle database realize when 2 users are going to get same data from data dictionary so it will use the same library cache (sql,pl/sql) for executing it . by doing this oracle database saves memory 


**Database buffer cache**
