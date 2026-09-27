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

## **4.1 pgBackRest**

**pgBackRest** is a backup and restore tool specifically designed for PostgreSQL. It supports physical backups, WAL archiving, compression, encryption, parallel processing, backup retention, and Point-in-Time Recovery (PITR).

It is commonly used when we need to manage PostgreSQL backups for large databases and want an automated backup strategy.

### Main Features

- Full, Differential, and Incremental backups
    
- WAL archiving
    
- Point-in-Time Recovery (PITR)
    
- Compression
    
- Encryption
    
- Parallel backup and restore
    
- Backup retention
    
- Backup verification
    
- Remote repositories
    
- Support for large PostgreSQL databases
    

### Backup Types

pgBackRest provides three main backup types:

**Full Backup**

A full backup copies the complete PostgreSQL cluster.

```bash
sudo -u postgres pgbackrest \
--stanza=main-stanza \
--type=full backup
```

**Differential Backup**

A differential backup contains changes since the last full backup.

```bash
sudo -u postgres pgbackrest \
--stanza=main-stanza \
--type=diff backup
```

**Incremental Backup**

An incremental backup contains changes since the previous backup.

```bash
sudo -u postgres pgbackrest \
--stanza=main-stanza \
--type=incr backup
```

### Check Backups

```bash
sudo -u postgres pgbackrest \
--stanza=main-stanza info
```

### Advantages

pgBackRest is useful when we need:

- High-performance backups
    
- Large database support
    
- Automated WAL management
    
- Different backup types
    
- Flexible retention policies
    
- Reliable PITR
    

---

## **4.2 Barman**

**Barman (Backup and Recovery Manager)** is a PostgreSQL backup and disaster recovery tool developed by **EnterpriseDB**.

Barman is mainly designed to centrally manage backups of one or multiple PostgreSQL servers.

Instead of keeping the backup management configuration only on the PostgreSQL server, Barman can act as a dedicated backup server.

### Main Features

- Physical PostgreSQL backups
    
- WAL archiving
    
- Point-in-Time Recovery (PITR)
    
- Multiple PostgreSQL server management
    
- Backup retention
    
- Backup verification
    
- Compression
    
- Remote backup management
    
- Backup catalog and metadata
    
- Disaster recovery support
    

### Barman Architecture

A typical Barman environment can look like this:

```text
+-----------------------+
| PostgreSQL Server     |
|                       |
| PostgreSQL Database   |
|          |            |
|          | WAL        |
+----------|------------+
           |
           v
+-----------------------+
| Barman Backup Server  |
|                       |
| Base Backups          |
| WAL Archives          |
| Backup Metadata       |
+-----------------------+
```

The PostgreSQL server sends its WAL files to the Barman server, while Barman manages the backup repository.

### PostgreSQL Configuration

For WAL archiving, PostgreSQL can be configured to send WAL files to Barman.

For example:

```ini
archive_mode = on
archive_command = 'barman-wal-archive barman-server main %p'
```

The exact configuration depends on the Barman server and the PostgreSQL environment.

### Taking a Backup

After configuring Barman, a backup can be created with:

```bash
barman backup main
```

Where `main` represents the configured PostgreSQL server.

### List Backups

```bash
barman list-backup main
```

### Check Server

```bash
barman check main
```

### Advantages

Barman is especially useful when:

- We have multiple PostgreSQL servers.
    
- We want a dedicated backup server.
    
- Backup management should be centralized.
    
- We need disaster recovery capabilities.
    
- We need long-term backup and WAL retention.
    

---

## **4.3 WAL-G**

**WAL-G** is a backup and restore tool designed for PostgreSQL and other databases. It focuses heavily on continuous archiving, cloud/object storage, compression, and fast backup and recovery.

WAL-G can store PostgreSQL backups and WAL files in remote storage such as:

- Amazon S3
    
- Google Cloud Storage
    
- Azure Blob Storage
    
- Other S3-compatible object storage
    

### Main Features

- Physical PostgreSQL backups
    
- WAL archiving
    
- Point-in-Time Recovery (PITR)
    
- Compression
    
- Encryption
    
- Cloud/object storage
    
- Incremental backups
    
- Backup verification
    
- Fast backup and restore
    
- Support for large databases
    

### WAL-G Architecture

A typical WAL-G environment can look like this:

```text
+-----------------------+
| PostgreSQL Server     |
|                       |
| PostgreSQL            |
|       |               |
|       | WAL           |
+-------|---------------+
        |
        v
+-----------------------+
| WAL-G                 |
|                       |
| Backup / WAL Upload   |
+----------|------------+
           |
           v
+-----------------------+
| Object Storage        |
|                       |
| Base Backups          |
| WAL Files             |
| Backup Metadata       |
+-----------------------+
```

The PostgreSQL server uses WAL-G to continuously send WAL files and backups to remote object storage.

### WAL Archiving

PostgreSQL can use WAL-G through the `archive_command`.

For example:

```ini
archive_mode = on
archive_command = 'wal-g wal-push %p'
```

Whenever PostgreSQL completes a WAL segment, WAL-G uploads it to the configured storage.

### Create a Backup

A base backup can be created with:

```bash
wal-g backup-push /var/lib/postgresql/16/main
```

### List Backups

```bash
wal-g backup-list
```

### Restore a Backup

```bash
wal-g backup-fetch /var/lib/postgresql/16/main LATEST
```

`LATEST` tells WAL-G to restore the latest available backup.

### Advantages

WAL-G is useful when:

- We want to store backups in cloud/object storage.
    
- We need continuous WAL archiving.
    
- We have large PostgreSQL databases.
    
- We want automated backup and recovery.
    
- We need geographically separated backup storage.
    
- We want to integrate PostgreSQL backups with cloud infrastructure.
    

---

# **4.4 Comparison**

The three tools provide similar core functionality but are designed around different operational approaches.

|Feature|pgBackRest|Barman|WAL-G|
|---|---|---|---|
|Physical Backup|Yes|Yes|Yes|
|WAL Archiving|Yes|Yes|Yes|
|PITR|Yes|Yes|Yes|
|Full Backup|Yes|Yes|Yes|
|Differential Backup|Yes|Yes|Yes|
|Incremental Backup|Yes|Yes|Yes|
|Compression|Yes|Yes|Yes|
|Encryption|Yes|Yes|Yes|
|Remote Storage|Yes|Yes|Yes|
|Cloud/Object Storage|Yes|Yes|Yes|
|Multiple PostgreSQL Servers|Yes|Yes|Yes|
|Centralized Backup Server|Possible|Yes|Possible|
|PostgreSQL Focus|Yes|Yes|Yes|

### Main Difference

The main difference is the way each tool approaches backup management.

**pgBackRest** provides a complete PostgreSQL backup framework with strong support for backup types, parallel processing, retention, WAL management, and PITR.

**Barman** is strongly focused on centralized backup and disaster recovery management, especially when multiple PostgreSQL servers are involved.

**WAL-G** focuses heavily on WAL archiving, fast backup/recovery, and integration with cloud and object storage.

All three tools can provide a reliable PostgreSQL backup strategy when they are correctly configured and, most importantly, when the restore process is regularly tested.