

### Possible Failure 

1. User Process failure 
2. Network failure 
3. Instance failure 
4. Media failure 
5. Inaccessible componants 
6. Physical corruptions
7. Logical corruptions
8. Inconsistencies
9. I/O failures 
10. Disaster 
11. External Incidents 
12. User error 


#### Defining Recovery Requirements

* Recovery Point Object (RPO)
* Recovery Time Objective (RTO)



*you may decide that where your backup file located.

| Backup and Recovery Objective | RTO                                                            | Oracle Solution                                         |
| ----------------------------- | -------------------------------------------------------------- | ------------------------------------------------------- |
| Physical data protection      | hours/days                                                     | RMAN <br>Oracle Secure Backup                           |
|                               | seconds/minutes                                                | Oracle Data Guard <br>Oracle Golden Gate <br>Oracle RAC |
| Human  Errors                 | minutes/hours                                                  | Flashback Technology <br>RMAN<br>Oracle Data Guard      |
| Recovery analysis             | minimize time for problem identification and recovery planning | Data Recovery Advisor                                   |


# what is FRA?

FRA is short of fast recovery area.
FRA is an Oracle-managed storage location for files needed for database backup and recovery.

##### 1. What can FRA store?

- RMAN backup pieces
    
- Archived redo logs
    
- Flashback logs
    
- Control file and SPFILE autobackups


![[Screenshot (12).png]]



1. check if your ASM is running 
```
SQL>  select instance_name , status
    from v$instance;
  2
INSTANCE_NAME    STATUS
---------------- ------------
orcl             OPEN

```

2. check if your Database can see ASM disk group

   ```
   SQL> select name , state , type , total_mb , free_mb
  2  FROM v$asm_diskgroup ;

NAME                           STATE       TYPE     TOTAL_MB    FREE_MB
------------------------------ ----------- ------ ---------- ----------
DATA                           CONNECTED   EXTERN      20476       2980

   ```


##### Fast recovery area space management 

- Alert issue 
  - Warning alert at 85%  free space in FRA 
  - Critical alert at 97% free space in FRA 

**when free space is needed :**
- Move backup files or delete them 
- Add additional disk 
- Change the RMAN retention policy 

*To avoid any undesirable result it is important to monitor space usage area*

```
SELECT
    NAME,
    ROUND(SPACE_LIMIT / 1024 / 1024 / 1024, 2) AS LIMIT_GB,
    ROUND(SPACE_USED / 1024 / 1024 / 1024, 2) AS USED_GB,
    ROUND(SPACE_RECLAIMABLE / 1024 / 1024 / 1024, 2)
        AS RECLAIMABLE_GB,
    ROUND(SPACE_USED / NULLIF(SPACE_LIMIT, 0) * 100, 2)
        AS USED_PERCENT,
    NUMBER_OF_FILES
FROM V$RECOVERY_FILE_DEST;
```


the result :

![[Screenshot (13).png]]



**RMAN Terminologies**
* Target Database 
* RMAN Client
* Media Management Software
* Recovery Catalog


   
##### create a backup user

```
create user BACKUPOPER IDENTIFIED BY oracle ;
grant SYSBACKUP TO BACKUPOPER;
GRANT CREATE SESSION TO BACKUPOPER;
```


#### Backup Terminology 

* Backup strategy may include :
  * Whole: Entire database
  * Partial: portion of database
* Backup type may indicate inclusion of:
  * Full : All data block within your chosen file
  * Incremental : Only Information that has changed since a previous backup.
    * Differential : Only backup from changed data 
    * Cumulative: changes since last level 0
* Backup mode may be :
  * Offline : 
  * online :



when RMAN is performing backup operation it generates backup files of one of the following types :

* Images 
* Backup sets 

RMAN is abe to take backup from following types of files :
* Datafiles
* Control files 
* Archive logs
* RMAN Backup
* server parameter files



#### Backup commands

```
BACKUP [AS BACKUPSET] DATABASE ---archive not included
BACKUP DATABASE PLUS ARCHIVELOG
```

Hot backup can not be running if the ARCHIVEMODE is off.

**Backup set : is a concept that include one or two backup pieces.**



#### Inconsistent and consistent backups
* Inconsistence backup (Online , Hot)
  
  ```
  BAKCUP DATABASE PLUS ARCHIVELOG
  ```
  
* Consistent backup (offline , cold )

  ```
  SHUTDOWN IMMEDIATE
  START MOUNT
  BACKUP DATABASE
  ALTER DATABASE OPEN
  ```


Specify the backup format in backup command:

```
BACKUP DATABASE FORMAT "/u02/oracl_%u"
```



 for ASM :
```
BACKUP DATABASE FORMAT '+BACKUP1';
```


# scenario 1

1. connect to oracle user
   
   ```
   su - oracle
   ```

2. connect to RMAN with SYSBACKUP 
   
   ```
   rman target "'/ as SYSBACKUP'"
   ```

3. Try to backup 
   
   ```
   BACKUP DATABASE
   ```


now you may get some Errors :

If you archive log was unable you will get :

```
ORA-01123: cannot start online backup; media recovery not enabled
```

for fixing this error alter your database and make archive log enable.

*Remember for doing this you should shutdown your database and start it in mount point to change your archive log mode.


```
sutdown immediate 
startup mount 
alter database archivelog
alter database open
```


another error you may see is :

```

RMAN-03009: failure of backup command on ORA_DISK_1 channel at 10/31/2026 13:56:10
ORA-19510: failed to set size of 32768 blocks for file "+DATA/ORCL/5AF82CC7FAEB146DE063844CA8C0B8D5/BACKUPSET/2026_10_31/nnndf0_tag20261031t135548_0.349.1248098169" (block size=8192)
ORA-17505: ksfdrsz:1 Failed to resize file to size 32768 blocks
ORA-15041: diskgroup "DATA" space exhausted
RMAN-03009: failure of backup command on ORA_DISK_1 channel at 10/31/2026 13:56:02
ORA-19510: failed to set size of 90112 blocks for file "+DATA/ORCL/5AF8122A7E927D4AE063844CA8C0C2F9/BACKUPSET/2026_10_31/nnndf0_tag20261031t135548_0.348.1248098155" (block size=8192)
ORA-17505: ksfdrsz:1 Failed to resize file to size 90112 blocks
ORA-15041: diskgroup "DATA" space exhausted
RMAN-03009: failure of backup command on ORA_DISK_1 channel at 10/31/2026 13:55:55
ORA-19510: failed to set size of 90112 blocks for file "+DATA/ORCL/BACKUPSET/2026_10_31/nnndf0_tag20261031t135548_0.348.1248098149" (block size=8192)
ORA-17505: ksfdrsz:1 Failed to resize file to size 90112 blocks
ORA-15041: diskgroup "DATA" space exhausted

```

it means you are out of space first you should delete your archive log or resize the FRA


delete archive log:

```
rman target 

delete archivelog all;
```

checking FRA size :

```

SELECT
    NAME,
    ROUND(SPACE_LIMIT / 1024 / 1024 / 1024, 2) AS TOTAL_GB,
    ROUND(SPACE_USED / 1024 / 1024 / 1024, 2) AS USED_GB,
    ROUND(SPACE_RECLAIMABLE / 1024 / 1024 / 1024, 2) AS RECLAIMABLE_GB,
    NUMBER_OF_FILES
FROM V$RECOVERY_FILE_DEST;
```
## save backups in special directory with special name 

1. with grid user :
   
   ```
   asmcmd 
   
   > cd DATA
   > cd ORCL
   > mkdir BACKUPS
   > 
   ```
2. With oracle user enter to RMAN 
   
   ```
   RMAN > CONFIGURE CHANNEL DVICE TYPR DISK FORMAT '+DATA/ORCL/BACKUPS/ORCL_FULL_%u.bkp';
   ``` 


##### Checking the used spaces 

```
select FILE_TYPE , PERCENT_SPACE_USED FROM V$RECOVERY_AREA_USAGE WHERE PERCENT_SPACE_USED<>0 ORDER BY PERCENT_SPACE_USED DESC;
```

result 

```
|FILE_TYPE   |PERCENT_SPACE_USED|
|:--         |:--               |
|REDO LOG    |        2.94      |
|ARCHIVED LOG|        0.84      |
|BACKUP PIECE|        0.09      |
|CONTROL FILE|        0.09      |
```


# Delete backup

#### No.1

```
RMAN> delete backupset of database;
```




# Monitoring

for monitor backup size and free spaces :


```

WITH BACKUP_INFO AS (
    SELECT NVL(SUM(BYTES), 0) AS BACKUP_BYTES
    FROM V$BACKUP_PIECE
    WHERE STATUS = 'A'
),
FRA_INFO AS (
    SELECT
        SPACE_LIMIT,
        SPACE_USED
    FROM V$RECOVERY_FILE_DEST
)
SELECT
    ROUND(B.BACKUP_BYTES / POWER(1024, 3), 2) AS BACKUP_SIZE_GB,

    ROUND(F.SPACE_LIMIT / POWER(1024, 3), 2) AS FRA_TOTAL_GB,

    ROUND(
        (F.SPACE_LIMIT - F.SPACE_USED) / POWER(1024, 3), 2
    ) AS FRA_REMAINING_GB

FROM BACKUP_INFO B
CROSS JOIN FRA_INFO F;

```

result:

```
|BACKUP_SIZE_GB|FRA_TOTAL_GB|FRA_REMAINING_GB|
|:--           |:--         |:--             |
|8.45          |20          |19.1            |
```


For monitoring all disk you have:

```
SELECT
    TYPE,
    COUNT(*) AS FILE_COUNT,
    ROUND(SUM(BYTES) / 1024 / 1024 / 1024, 2) AS SIZE_GB
FROM V$ASM_FILE
GROUP BY TYPE
ORDER BY SIZE_GB DESC;
```

result:

```
|DISKGROUP|TOTAL_GB|USED_GB|FREE_GB|USED_PERCENT|
|:--      |:--     |:--    |:--    |:--         |
|DATA     |20      |15.95  |4.05   |79.76       |
```


to see what file use how much space:

```
SELECT
    TYPE,
    COUNT(*) AS FILE_COUNT,
    ROUND(SUM(BYTES) / 1024 / 1024 / 1024, 2) AS SIZE_GB
FROM V$ASM_FILE
GROUP BY TYPE
ORDER BY SIZE_GB DESC;

```


result:

```
|TYPE         |FILE_COUNT|SIZE_GB|
|:--          |:--       |:--    |
|BACKUPSET    |30        |16.79  |
|DATAFILE     |12        |5.28   |
|ONLINELOG    |6         |1.17   |
|TEMPFILE     |3         |0.62   |
|ARCHIVELOG   |13        |0.22   |
|AUTOBACKUP   |3         |0.05   |
|CONTROLFILE  |2         |0.04   |
|PARAMETERFILE|1         |0      |
```
