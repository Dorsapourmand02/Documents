
1- check environments

```
SQL> select name , open_mode , database_role
  2  from v$database;

NAME      OPEN_MODE            DATABASE_ROLE
--------- -------------------- ----------------
ORCL      READ WRITE           PRIMARY
```

```

SQL> select instance_name , status , version
  2  from v$instance;

INSTANCE_NAME    STATUS       VERSION
---------------- ------------ -----------------
orcl             OPEN         19.0.0.0.0


```
```
|NAME   |CON_ID|OPEN_MODE |
|:--    |:--   |:--       |
|ORCLPDB|   3  |READ WRITE|
```


from Linux env:

```
hostname 
oraclehost

```

```
ip addr 
192.168.76.132
```

```
free -h
              total        used        free      shared  buff/cache   available
Mem:           7.5G        1.8G        773M        2.9G        4.9G        2.7G
Swap:          7.9G          0B        7.9G

```

```
df -h
Filesystem           Size  Used Avail Use% Mounted on
devtmpfs             3.8G     0  3.8G   0% /dev
tmpfs                3.8G  637M  3.2G  17% /dev/shm
tmpfs                3.8G  9.8M  3.8G   1% /run
tmpfs                3.8G     0  3.8G   0% /sys/fs/cgroup
/dev/mapper/ol-root   50G   27G   24G  53% /
/dev/mapper/ol-home   42G  5.1G   37G  13% /home
/dev/sda1           1014M  228M  787M  23% /boot
tmpfs                771M   48K  771M   1% /run/user/1000
tmpfs                771M     0  771M   0% /run/user/54321

```