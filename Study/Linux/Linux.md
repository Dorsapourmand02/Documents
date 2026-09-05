

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


