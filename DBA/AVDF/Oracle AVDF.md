
AVDF is Comprehensive database activity monitoring solutions.

This feature gives us Complete visibility on database activities .

**WHAT IS REALLY HAPPENING ON YOUR DATABASE?**
**WHO IS DOING WHAT ON YOUR DATABASE?**

Monitoring database is important for avoiding and preventing the incidents and illegal behavior in database.
DAM(oracle recommendation) is a security technology for monitoring database .


AVDF is a combination of Database auditing and Network monitoring.

**Auditing collection:**
- Privileged users 
- Suspicious Activity monitoring --> users who access the database during unusual hours , multiplied failed user login.
- Security relevant event auditing --> security management , account management , Activity of using system 
- Sensitive data access auditing

**Database Firewall**
 - Session context --> Define trusted path to app basis on DB/OS user name , client IP 
 - Default rule --> Action on unknown SQL traffic 
 - SQL statement --> Create white list set of allowed applications  SQL statement (who is running what)
 - Database object ---> Prevent and monitor sensetive data and objects of applications 



**Database Auditing**
Creating or enabling database policies to track the actions taken on the database , objects and users.

If auditing is enables it will produce a trail of these operations which are happening where , when and by who.

Database auditing is not only for local auditing but also any database activity that does not only capture local activity.

**Database Firewall**
Monitoring and analyzing the SQL traffic to database.(Doesn't matter that comes from applications or user directly)
Firewall recognize all attacks which coming thwarting SQL injection or any other kinds.

Firewall policy require that trusted path access to corporate applications should enforced .This trust let applications connect to database from certain IP address or users.

```

Firewall policies -----> monitor
                  -----> Alert 
                  -----> Block 
                  -----> Substitude SQL Standard 

```

This happen base on user session information such as IP address or database username.

Database Firewall Train to understand normal or approved SQL and block every other things.

**Oracle recommend to Database activity monitoring requiring both SQL Auditing and SQL traffic monitoring**


Auditing typically captures ==detailed information after a certain event has occurred==, while monitoring SQL traffic helps you ==monitor the SQL statement before it reaches the database==, **making it possible to block suspicious statements**.


# **AVDF Components**

AVDF has 3 main components 
1- Audit vault server 
2- Audit vault agent
3- Database Firewall



###### **Audit Vault Server**

The Audit Vault Server is a mandatory component of AVDF. The Audit vault server is a complete App. It contains:

```
Hardened Oracle linux operating system 
Oracle Database (NOT USUAL AND NORMAL ONE)
AVDF application
```

###### **Hardened Oracle Linux operating system**
In this part we should :
delete all useless and extra services 
Close all unnecessary IP addresses 
More security 
and access restricted 

###### **Oracle Database**
This is not a normal database because it keeps all audit vault logs. Also it use TDE for more security so if some one still the files they can not read the files (EVEN DBA.)


###### **AVDF applications**

It is application on the server so we can do all the following stuff with it :

```
1- See all reports 
2- Define policy 
3- See Alerts 
4- Mangage all Targets 
```

This application contains :

1- Web Console 
2- AVCLI 


**Web console**
We open it with browser 

**AVCLI**
A Command line interface


A general view of Audit vault server :


```
        Audit Vault Server
        ┌────────────────────────────┐
        │                            │
        │ 1. Hardened Linux OS       │
        │                            │
        │ 2. Oracle Database         │
        │    (Audit Repository)      │
        │    - TDE Encryption        │
        │    - Database Vault        │
        │                            │
        │ 3. AVDF Application        │
        │    - Web Console           │
        │    - AVCLI                 │
        │                            │
        └────────────────────────────┘
```

