

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



