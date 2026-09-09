

Patching directly modifies binary files and system tables. Always take a full, verified cold backup (or create an RMAN backup and Guaranteed Restore Point) before starting.

This document details the step-by-step procedure followed to successfully apply **Patch 37960098: Database Release Update 19.28.0.0.250715** (DBRU) to an Oracle Database 19c home on Linux. The methodology adheres strictly to the official Oracle Patch README for manual application in non-RAC / single-instance database environments.

## 1. Environment Overview

| Parameter              | Value / Details                                           |
| ---------------------- | --------------------------------------------------------- |
| **Operating System**   | Oracle Linux (x86_64)                                     |
| **Database Version**   | Oracle Database 19c (Release 19.3.0.0.0 baseline)         |
| **Target Patch ID**    | 37960098 (Database Release Update 19.28.0.0.250715)       |
| **OPatch Requirement** | Version 12.2.0.1.46 or later (Upgraded via Patch 6880880) |
| **Application Method** | Manual `opatch apply` (Non-RAC / Database Home focus)     |

## 2. Phase 1: OPatch Utility Upgrade

As specified in Section 2.1 of the patch README, applying DBRU 19.28 requires OPatch version **12.2.0.1.46 or higher**. 

### Step 1.1: Replace OPatch Binaries

Executed to extract/copy the updated OPatch package (Patch 6880880) into the Oracle Database Home:

Bash

```
cp -rf OPatch /u01/app/oracle/product/19.3.0/dbhome_1/
chown -R oracle:oinstall /u01/app/oracle/product/19.3.0/dbhome_1/OPatch
```

### Step 1.2: Verify OPatch Version

Executed as the `oracle` user to verify that the utility meets the required build version:

Bash

```
su - oracle
$ORACLE_HOME/OPatch/opatch version
```

## 3. Phase 2: Patch Pre-Installation Procedures

### Step 2.1: Extract Patch Archive

Extracted the patch zip file `p37960098_190000_Linux-x86-64.zip` into a temporary directory:

Bash

```
unzip -q p37960098_190000_Linux-x86-64.zip -d /tmp/opatch/
chmod -R 777 /tmp/opatch/37960098
```

### Step 2.2: Shutdown Instances and Listeners

As per Section 3.2 of the README for non-RAC environments, all database instances and listeners running out of the target Oracle Home were gracefully shut down prior to binary modification:

Bash

```
grid user:
# Shutdown Listener
lsnrctl stop


oracle user:
# Shutdown Database Instance
sqlplus / as sysdba
SQL> SHUTDOWN IMMEDIATE;
SQL> EXIT;
```

### Step 2.3: Environment & Process Check

Verified that no Oracle processes remained active in the background and validated environment variables:

Bash

```
ps -ef | grep pmon
echo $ORACLE_HOME
```

## 4. Phase 3: Patch Application (Binary Deployment)

### Step 3.1: Execute OPatch Apply

Navigated to the extracted patch directory and executed the `opatch apply` command as the `oracle` user:

Bash

```
cd /tmp/opatch/37960098
$ORACLE_HOME/OPatch/opatch apply
```

Responded `y` to prompt validations. The utility updated all binaries, header files, and shared libraries within `$ORACLE_HOME`.

> **Status Outcome:** `OPatch succeeded.`

## 5. Phase 4: Post-Installation Procedures

### Step 4.1: Permission Fixes for SQLPatch Executable

Encountered an execution permission issue (`Permission denied`) when invoking `datapatch`. Corrected directory permissions across the `sqlpatch` path:

Bash

```
chmod -R 755 $ORACLE_HOME/sqlpatch
```

### Step 4.2: Startup Database and Pluggable Databases

Started the listener and restarted the database instance to load the updated binary executables:

Bash

```
grid user:
# Start Listener
lsnrctl start

oracle user:
# Start Database Instance & PDBs
sqlplus / as sysdba
SQL> STARTUP;
SQL> ALTER PLUGGABLE DATABASE ALL OPEN;
SQL> EXIT;
```

### Step 4.3: Execute Datapatch Utility

As specified in Section 3.3.2 of the README, ran the `datapatch` tool to load modified SQL, PL/SQL packages, and database catalog definitions into the data dictionary:

Bash

```
cd $ORACLE_HOME/OPatch
./datapatch -verbose
```

> **Status Outcome:** `SQL Patching tool complete.`

## 6. Phase 5: Verification & Validation

### Step 5.1: SQL Registry Verification

Connected to the database via SQL*Plus and queried `dba_registry_sqlpatch` to verify post-installation SQL updates:

SQL

```
sqlplus / as sysdba

SET LINESIZE 200
COL PATCH_ID FOR 99999999
COL ACTION FOR A10
COL STATUS FOR A15
COL ACTION_TIME FOR A30
COL DESCRIPTION FOR A50

SELECT patch_id, action, status, action_time, description 
FROM dba_registry_sqlpatch;
```

**Result:** Verified that Patch **37960098** is registered with `ACTION = APPLY` and `STATUS = SUCCESS`.

### Step 5.2: Inventory Inspection

Verified that the patch is correctly indexed in the Local Inventory:

Bash

```
$ORACLE_HOME/OPatch/opatch lsinventory
```