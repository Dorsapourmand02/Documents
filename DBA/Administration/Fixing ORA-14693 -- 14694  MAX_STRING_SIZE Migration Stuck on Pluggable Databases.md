

## Symptom

CDB pluggable databases stuck in `MOUNTED` state, refusing to open:

```
SQL> alter pluggable database all open;
ORA-14694: database must in UPGRADE mode to begin MAX_STRING_SIZE migration
```

Even after setting `MAX_STRING_SIZE=EXTENDED` and restarting the CDB in upgrade mode, opening an individual PDB in upgrade mode kept failing:

```
SQL> alter pluggable database ORCL_PDB open upgrade;
ORA-14693: The MAX_STRING_SIZE parameter must be EXTENDED.
```

## Root Cause

`MAX_STRING_SIZE` is modifiable per-container. The **CDB root** had been migrated to `EXTENDED` successfully, but each **PDB never had its own explicit override set** — it was only inheriting the root's value for display purposes (`SHOW PARAMETER` looked fine), while internally each PDB's own dictionary still expected the migration to happen. This mismatch is what produced `ORA-14693` when trying to open a PDB in upgrade mode.

## The Fix (Step by Step)

### 1. Put the whole CDB into upgrade mode

```sql
SHUTDOWN IMMEDIATE;
STARTUP UPGRADE;
```

### 2. Confirm/re-run the migration at the CDB root

```sql
ALTER SESSION SET CONTAINER = CDB$ROOT;
@?/rdbms/admin/utl32k.sql
```

### 3. For EACH pluggable database, set an explicit override and open it in upgrade mode

This was the missing step — the PDB needs its **own** `ALTER SYSTEM SET` while the CDB is still in the upgrade session:

```sql
ALTER SESSION SET CONTAINER = ORCL_PDB;
ALTER SYSTEM SET MAX_STRING_SIZE=EXTENDED SCOPE=SPFILE;

ALTER SESSION SET CONTAINER = CDB$ROOT;
ALTER PLUGGABLE DATABASE ORCL_PDB OPEN UPGRADE;
```

### 4. Run the migration script inside that PDB

```sql
ALTER SESSION SET CONTAINER = ORCL_PDB;
@?/rdbms/admin/utl32k.sql
```

### 5. Repeat steps 3–4 for every other PDB (e.g. DORSA)

Do this for all affected PDBs **before** leaving the CDB's upgrade session — it avoids having to cycle the whole instance in and out of upgrade mode multiple times.

### 6. Bring the whole CDB back to normal mode

```sql
ALTER SESSION SET CONTAINER = CDB$ROOT;
SHUTDOWN IMMEDIATE;
STARTUP;
```

### 7. Open all PDBs normally

```sql
ALTER PLUGGABLE DATABASE ALL OPEN;
```

## Key Takeaways

- **`SHOW PARAMETER MAX_STRING_SIZE` at the CDB root doesn't guarantee each PDB is actually migrated.** Each PDB can — and in this case needed to — carry its own explicit `ALTER SYSTEM SET MAX_STRING_SIZE=EXTENDED SCOPE=SPFILE` while connected to that PDB's container.
- **`ALTER PLUGGABLE DATABASE <pdb> OPEN UPGRADE` should be run while the whole CDB instance is still in `STARTUP UPGRADE` mode** — not after cycling the CDB back to normal mode first. Migrating PDBs is meant to happen inside the same upgrade session as the root (this is what Oracle's `catcon.pl --force_pdb_mode UPGRADE` automates in production environments with many PDBs).
- A PDB can only be fully `OPEN` (normal mode) once the **entire CDB instance** has returned to normal (non-upgrade) status — attempting to open a PDB normally while the instance is still `OPEN MIGRATE` throws `ORA-65054`.
- Useful diagnostic queries used along the way:
    - `SHOW PDBS;` / `SELECT open_mode FROM v$pdbs;`
    - `SELECT status FROM v$instance;`
    - `SELECT * FROM pdb_plug_in_violations WHERE pdb_name = '<PDB>';`
    - `SELECT con_id, comp_id, version, status FROM cdb_registry WHERE comp_id = 'CATALOG';`
    - `SHOW PARAMETER max_string_size;` / `SHOW PARAMETER compatible;`