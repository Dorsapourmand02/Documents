Postgre has 4 method to do backups :
1- Logical Backup 
2-Physical Base Backup 
3-Continuous Archiving and PITR 
4-Backup with enterprise tools

# **1-Logical backup**
Logical backups export database objects into SQL commands or a custom archive file.

- **Single Database Backup (Custom Format - Recommended):**
    
    Bash
    
    ```
    pg_dump -U username -F c -b -v -f mydb_backup.dump mydb
    ```
    
- **Restore Single Database:**
    
    Bash
    
    ```
    pg_restore -U username -d mydb_restored -v mydb_backup.dump
    ```
    
- **Entire Cluster Backup (All Databases & Roles):**
    
    Bash
    
    ```
    pg_dumpall -U username > full_cluster_backup.sql
    ```
    

> **Trade-off:** High flexibility (can restore individual tables or migrate across OS/architecture), but slow for databases over ~100 GB.



# **2-Physical base backup**

Instead of doing backup  directly from disk it will backup from data directory .
All tables , indexes and filesystems are being saved in the data directory .
But you should also know that database is writing on the disk frequently so if some changes happen while you're doing this, backup would be corrupted.

In  this method we have two restrictions :

1-Offline/cold backup 

2- Online/hot backup with snapshots 


**Offline/cold backup 

1.1- Find the config files 

```
psql -U postgres -c "SHOW data_directory;"
```

1.2-service will be stop

```

sudo systemctl stop postgresql

sudo systemctl status postgresql

```

1.3-Create Archive files and copy data

```
sudo mkdir -p /var/backups/postgres

sudo tar -czvf /var/backups/postgres/cold_backup_$(date +%Y%m%d).tar.gz /var/lib/postgresql/16/main
```

1.4 - start the database 

```
sudo systemctl start postgresql
```


# **3-Contious Archiving and PITR**

this back up is a mixed up of WAL with Base backup.

 WAL : Postgre  before applying the changes on the main data write all changes on the log files which we call it WAL.

WAL Archiving : After the WAL get filling up postgre move them in somewhere safe which we call it WAL Archiving.

Base Backup : A copy from data directory.

PITR : A composition of base backup and  WAL for reaching to exact time we wanna take backup.

3.1-Stop the service

```
sudo systemctl stop postgresql
```

3.2- Empty the pgdata(main data directory) 

```
sudo mv /var/lib/postgresql/16/main /var/lib/postgresql/16/main_corrupted
sudo mkdir -p /var/lib/postgresql/wal_archive
sudo chown -R postgres:postgres /var/lib/postgresql/wal_archive
```

3.3- Transfer all the base backup files to data direcotries 

```
sudo cp -r /var/backups/postgres/base_backup/* /var/lib/postgresql/16/main/
sudo chown -R postgres:postgres /var/lib/postgresql/16/main
```

3.4- set the recovery point 

```
sudo touch /var/lib/postgresql/16/main/recovery.signal
sudo chown postgres:postgres /var/lib/postgresql/16/main/recovery.signal
```

3.4-add these following at the end of the postgresql.conf in the main 

```
restore_command = 'cp /var/lib/postgresql/wal_archive/%f %p'
recovery_target_time = 'YYYY-MM-DD hh:mm:ss'
recovery_target_action = 'promote'
```

3.5- Restart the service 

```
systemctl start postgresql
```

# **4-Backup with enterprise tools**

we have 3 tools:
1-pg BackRest
2-Barman
3- WAL-G


**pg BackRest**

pgBackRest is optimized for speed, reliability, and handling multi-terabyte databases.

1.Installation

```
sudo apt install pgbackrest

sudo dnf install pgbackrest

sudo mkdir -p /var/lib/pgbackrest 
sudo chmod 700 /var/lib/pgbackrest 
sudo chown postgres:postgres /var/lib/pgbackrest
```

2.pgBackRest structure

we should put this following inside the config file

```
etc/pgbackrest/pgbackrest.conf

[global]
repo1-path=/var/lib/pgbackrest
repo1-retention-full=2
process-max=4
log-level-console=info
log-level-file=detail
start-fast=y
compress-type=zst

[main-stanza]
pg1-path=/var/lib/postgresql/16/main
pg1-user=postgres
```


3.set the postgresql so we can send the WALs to pgBackRest

```
postgresql.conf

wal_level = replica
archive_mode = on
archive_command = 'pgbackrest --stanza=main-stanza archive-push %p'
max_wal_senders = 3
```

4.Restart the service

```
sudo systemctl restart postgresql
```

5.Create and Check the Stanza

Before taking backups, you must initialize the **stanza** (the configuration scope that ties pgBackRest to your specific PostgreSQL database cluster) and verify that WAL archiving is working.

Bash

```
# 1. Initialize the stanza
sudo -u postgres pgbackrest --stanza=main-stanza stanza-create

# 2. Validate configuration and test archive_command connection
sudo -u postgres pgbackrest --stanza=main-stanza check
```

> **Verification:** The `check` command will force PostgreSQL to switch a WAL segment and push it to `/var/lib/pgbackrest`. If it completes without errors, your WAL archiving pipeline is operational.

# 6.Taking Backups

pgBackRest supports three types of physical backups: **Full**, **Differential**, and **Incremental**.

#### A. Full Backup

Copies every file in the database cluster. Required as the baseline for all subsequent backups.

Bash

```
sudo -u postgres pgbackrest --stanza=main-stanza --type=full backup
```
