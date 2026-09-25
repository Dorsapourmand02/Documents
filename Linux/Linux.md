

linux architecture 

Hardware --> kernel --> shell  --> urilities

kernel is what which is speaking to the hardware.


General system area :
Process
Memory 
Device Driver 
System call

system call -> 1- fork() 2- exec()

fork
Process A |||--->exec
      |----->copy of process A  ---> exec

process :
1- foreground
2- background

Daemon : the process which is run in the background like service


commands :

bg --> took the process to the background
fg --> we put the  process in the foreground
job --> with this we can see all the processes in the background 
top --> with this you can see which user are using more what 



sleep 10 & ---> the system wont do anything in 10 sec and we put it in the background 
with jobs you can  see it 
and with 
`ps -aus | grep  sleep` 

you can see more detail with PID
so if you want to kill it you can use it.

`kill PID`

Zombies?
when a parent process be killed the child would be called zombie



iotop --> shows  who is using more I/O --> remmember use it only in root user

what is Repository ?
It is where the packages are be.


apt command : be use for upgrading installing 


# Partitioning 

Physical disk is like :

```
sda                         8:0    0   64G  0 disk
```

this physical disk can divided into separate section which we call it partitions .

```
sda                         8:0    0   64G  0 disk 

├─sda1                      8:1    0    1G  0 part /boot/efi

├─sda2                      8:2    0    2G  0 part /boot

└─sda3                      8:3    0 60.9G  0 part 

  └─ubuntu--vg-ubuntu--lv 252:0    0 30.5G  0 lvm  /
```


each partition is separate region of disk. But there are bot FILE SYSTEM .
The next step usually is put File system on them .

so the basic relation is :

```
DISK ---> PARTITIONS ---> FILE SYSYTEM ---> MOUNT POINT
```

**Commands tool**
- **lsblk** : It shows block_device hierarchy 
- **fdisk** : we can create partitions with it 
- **Parted** : Useful for GPT , large disks and scripting   


**Create disk and add partitions**

1- Turn of your vm and in the setting add a hard disk with the size you need.
2- Turn on the VM and check if it added 

```
vagrant@Dori$: lsblk

NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS

sda                         8:0    0   64G  0 disk 

├─sda1                      8:1    0    1G  0 part /boot/efi

├─sda2                      8:2    0    2G  0 part /boot

└─sda3                      8:3    0 60.9G  0 part 

  └─ubuntu--vg-ubuntu--lv 252:0    0 30.5G  0 lvm  /

sdb                         8:16   0   10G  0 disk


```

3- If you saw your new disk its time to go to next step which is partitioning . for doing that you should :


```
sudo fdisk 

command : m --> see helps 

command : n --> create new partition

command : p --> primary 

command : ENTER 

command : ENTER 

command : w --> save and exit
```

4- Verify it 

```
**vagrant@Dori**:**~**$ lsblk

NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS

sda                         8:0    0   64G  0 disk 

├─sda1                      8:1    0    1G  0 part /boot/efi

├─sda2                      8:2    0    2G  0 part /boot

└─sda3                      8:3    0 60.9G  0 part 

  └─ubuntu--vg-ubuntu--lv 252:0    0 30.5G  0 lvm  /

sdb                         8:16   0   10G  0 disk 

└─sdb1                      8:17   0   10G  0 part
```

5- Now its time for adding file system first check if the partitions is empty 

```

**vagrant@Dori**:**~**$ lsblk -f

NAME                      FSTYPE      FSVER    LABEL UUID                                   FSAVAIL FSUSE% MOUNTPOINTS

sda                                                                                                        

├─sda1                    vfat        FAT32          58F1-BD52                                   1G     1% /boot/efi

├─sda2                    ext4        1.0            b8cd9c1e-487d-412b-882b-edeb25fd98bc      1.7G     5% /boot

└─sda3                    LVM2_member LVM2 001       LiMwNf-sOoa-nqO0-4EIg-NMUU-koMV-BDIkTL                

  └─ubuntu--vg-ubuntu--lv ext4        1.0            888b31cd-b00c-47cb-83d0-01ecaea0a803     22.8G    18% /

sdb                                                                                                        

└─sdb1
```

6- now time for adding file system 

```
sudo mkfs.ext4 /dev/sdb1
```

7- now check that the file system added

```
**vagrant@Dori**:**~**$ lsblk -f

NAME                      FSTYPE      FSVER    LABEL UUID                                   FSAVAIL FSUSE% MOUNTPOINTS

sda                                                                                                        

├─sda1                    vfat        FAT32          58F1-BD52                                   1G     1% /boot/efi

├─sda2                    ext4        1.0            b8cd9c1e-487d-412b-882b-edeb25fd98bc      1.7G     5% /boot

└─sda3                    LVM2_member LVM2 001       LiMwNf-sOoa-nqO0-4EIg-NMUU-koMV-BDIkTL                

  └─ubuntu--vg-ubuntu--lv ext4        1.0            888b31cd-b00c-47cb-83d0-01ecaea0a803     22.8G    18% /

sdb                                                                                                        

└─sdb1                    ext4        1.0            fb8bc028-18bc-4f73-afbb-7d10cbdcad26
```

8- Now create a mount point call it /data 

```
sudo mkdir /data

```

9-Mount 

```
sudo mount /dev/sdb1 /data
```

10-Check

```
**vagrant@Dori**:**~**$ lsblk

NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS

sda                         8:0    0   64G  0 disk 

├─sda1                      8:1    0    1G  0 part /boot/efi

├─sda2                      8:2    0    2G  0 part /boot

└─sda3                      8:3    0 60.9G  0 part 

  └─ubuntu--vg-ubuntu--lv 252:0    0 30.5G  0 lvm  /

sdb                         8:16   0   10G  0 disk 

└─sdb1                      8:17   0   10G  0 part /data
```

why we do partitioning ?
- separate different type of data
- file system organization 
- Security : eg --> Separate /var prevent log growth from filling the root file system.
- Different storage requirement

