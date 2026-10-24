# Oracle Audit Vault and Database Firewall (AVDF)

## Technical Overview, Prerequisites, Installation Plan, and Validation Checklist

Oracle Audit Vault and Database Firewall (AVDF) is a database security platform designed to centralize audit collection, monitor database SQL traffic, detect suspicious activity, enforce database security policies, and provide reports and alerts for security investigations and compliance.

**WHAT IS REALLY HAPPENING ON YOUR DATABASE?**

**WHO IS DOING WHAT ON YOUR DATABASE?**

#### What does AVDF  do?

**Centralized Audit Collection**

AVDF gathers audit records from supported databases and other target systems.
- Successful and failed database logins.
    
- Privileged-user activities.
    
- DDL operations such as `CREATE`, `ALTER`, and `DROP`.
    
- DML operations such as `INSERT`, `UPDATE`, and `DELETE`.
    
- Access to sensitive objects.
    
- Changes to database security configurations.
    

**Security Monitoring and Reporting**

AVDF provides a central interface for reviewing collected audit events, investigating suspicious activity, generating reports, and configuring alerts.

Typical use cases include:

- Investigating who accessed a sensitive table.
    
- Reviewing privileged DBA activities.
    
- Identifying repeated failed login attempts.
    
- Tracking changes to database objects.
    
- Supporting compliance and audit investigations.


**SQL Traffic Monitoring**

AVDF combines two principal appliances: the Audit Vault Server and the Database Firewall.

The Database Firewall analyzes SQL traffic from clients and applications to supported database targets.

Depending on the deployment mode and configured policies, it can:

- Monitor SQL statements.
    
- Record network events.
    
- Generate alerts for policy violations.
    
- Block or substitute SQL statements in supported Proxy-mode configurations.
    

#### AVDF Combination

**Audit vault server:**

- Collects and stores audit information from supported targets.
    
- Manages audit policies, reports, alerts, and administrative interfaces.
    
- Provides a centralized location for audit investigations.
    
- Manages registered targets and their associated audit collection configurations.
    

**Database Firewall:**

- **Session Context** --> Defines a trusted path to an application based on information such as database username, client IP address, and other available session attributes.
    
- **Default Rule** --> Defines the action to take on SQL traffic that does not match the configured policy rules.
    
- **SQL Statement** --> Allows administrators to define policies based on approved SQL statements and application behavior (who is running what).
    
- **Database Object** --> Helps monitor and protect sensitive data and application database objects according to configured policies.
    

**Database Auditing**

Creating or enabling database audit policies allows us to track actions performed on the database, its objects, and its users.

If auditing is enabled and configured correctly, the database produces an audit trail containing information about operations, including where, when, and by whom they were performed.

Database auditing is not limited to local auditing. Depending on the configured audit sources and collection mechanisms, AVDF can also collect audit records from supported remote databases and other supported target systems.

**Database Firewall**

The Database Firewall monitors and analyzes SQL traffic going to the database. It does not matter whether the traffic comes from an application or a user connecting directly, provided that the traffic passes through a monitoring point visible to the firewall.

The Database Firewall can detect suspicious SQL activity, including patterns associated with SQL injection and other database attacks. However, detection depends on the deployment architecture, policy configuration, supported traffic, and the attack pattern.

Firewall policies can enforce trusted paths for access to corporate applications. This trust allows administrators to define which database access patterns are considered legitimate based on attributes such as client IP address, database username, and application context.

```

Firewall policies -----> monitor
                  -----> Alert 
                  -----> Block 
                  -----> Substitude SQL Standard 

```

The action depends on the configured policy and the deployment mode. Blocking and SQL substitution require a supported enforcement configuration; they are not available in every monitoring deployment.

This can happen based on user session information, such as the client IP address or database username, together with SQL statement characteristics and other available session attributes.

The Database Firewall can use learned or explicitly defined SQL policies to identify normal or approved SQL activity and detect or block traffic that violates those policies. It does not automatically guarantee that every attack will be detected or that every unrecognized statement will be blocked.

**Oracle recommends combining database auditing with SQL traffic monitoring when comprehensive database activity monitoring is required.**

Auditing typically captures detailed information about database events that have occurred, while monitoring SQL traffic can analyze statements before they reach the database when the traffic passes through an appropriate monitoring or enforcement point. This makes it possible to detect suspicious statements and, in supported deployment modes, block them before execution.


## **AVDF Components**

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




# **Installation steps**


1- Base on the prerequisites Install a machine on the VM and start the machine .

2- The installation continues with the following prompts on the screen one after another: 

```
Installing AVDF bootstrap Beginning installation of Audit Vault Server dependencies Creating repository. Relinking Oracle Database Installing AVS application. OR Installing Database Firewall. Migrating repository to ASM storage Updating Oracle Audit Vault and Database Firewall data Updating UI
```

3- The installer prompts for network configuration. Select the appropriate network interfaces and click OK.

4- The following Network settings screen appears.

![[Screenshot (11).png]]

for this part in your database machine run this following command :

```

[oracle@oraclehost ORCL]$ ip route
default via 192.168.76.2 dev ens33 proto dhcp metric 100
192.168.76.0/24 dev ens33 proto kernel scope link src 192.168.76.132 metric 100
192.168.122.0/24 dev virbr0 proto kernel scope link src 192.168.122.1 linkdown

```

**the Gateway would be : 192.168.76.2**
**Network Mask : 255.255.255.0**

IP address should be in the Permissible Range. first check your database machine IP

```
ip addr 
```


now go to VMware and Edit > virtual network editor > DHCP setting 
now you can see the starting an ending Range  of IP address . Choose an IP.


after it is done successfully you will see this following message:

```
Audit Vault Server 20.1.0.0.0 installation has completed. Post install configuration steps must be completed using the appliance administration console ...
```

5- After installation:

- Confirm that the VM boots successfully.
    
- Confirm that its configured network interface has the expected IP address.
    
- Check connectivity from an appropriate host on the lab network.
    
- Confirm that the AVS web console becomes available according to the release-specific instructions.


6- Complete AVS configuration :

6.1-  From a browser that can reach AVS, open the console URL specified in the AVDF 20.18 post-installation guide. The usual format is:

```text
https://<AVS-IP>/console
```

Confirm the exact URL for the installed release.

If the browser displays a certificate warning, verify that the address belongs to your lab appliance before proceeding.


6.2- Complete the initial setup wizard

Follow the prompts to configure the initial AVS environment.

Depending on the installation workflow, this can include:

- Creating the Super Administrator account.
    
- Setting administrative credentials.
    
- Configuring repository encryption credentials.
    
- Setting time and NTP configuration.
    
- Completing the initial system configuration.
    

Store all credentials securely. Do not place passwords in this document.

 6.3- Validate AVS

Verify that:

- The console is accessible.
    
- The initial administrator can sign in.
    
- The appliance reports a healthy state.
    
- The system time is correct.
    
- The installed release is the intended AVDF version.
    

At this stage, AVS is installed, but database audit collection and Database Firewall monitoring are not necessarily configured.

7- Create the Database Firewall VM

1. Create a new VM named `DBFW-LAB`.
    
2. Allocate sufficient CPU, RAM, and local disk resources.
    
3. Configure the number of network adapters required by the selected deployment mode.
    
4. Connect the management adapter to the appropriate lab network.
    
5. Configure any additional client-side, database-side, or monitoring interfaces required by the topology.
    
6. Attach the Database Firewall ISO to the virtual CD/DVD drive.
    
7. Enable **Connect at power on**.
    

Do not attach the Firewall ISO to the AVS VM for installation


7.1- Boot and install Database Firewall

1. Power on the Database Firewall VM.
    
2. Boot from the attached ISO.
    
3. Confirm that the intended AVDF release is being installed.
    
4. Follow the installer's on-screen instructions.
    
5. Set and confirm the requested root password.
    
6. Allow the installer to prepare the appliance disk and install the software.
    
7. Wait for the installation to complete.
    
8. Reboot when instructed.


7.2- Configure Firewall networking

Enter the network information required by the installer:

- A unique IP address for the Firewall management interface.
    
- The correct network mask.
    
- The appropriate gateway, if required.
    

The Firewall IP must not be the AVS IP or the database IP.

Record the IP addresses and identify which virtual NIC serves each role in the chosen topology. 

8- Associate Datbase firewall with AVS 

Once both appliances are installed, configure the relationship between them.

8.1- Obtain the AVS certificate

In the AVS console, locate the certificate-management section specified by the AVDF 20.18 documentation.

Obtain the AVS server certificate or certificate information required by the Firewall registration procedure.

Menu names can vary by release and patch level.

8.2- Configure the Firewall association

1. Open the Database Firewall configuration interface as documented for the installed release.
    
2. Enter the AVS IP address.
    
3. Supply the required AVS certificate information.
    
4. Complete the association procedure.
    
5. Return to the AVS console.
    
6. Open the Database Firewalls management section.
    
7. Register the Firewall using its management IP and the required identification details.
    

8.3- Verify registration

Confirm that:

- The Firewall appears in AVS.
    
- The association and certificate configuration are valid.
    
- The Firewall is online or available.
    
- The required management communication works.
    

An online Firewall does not automatically mean that it is receiving SQL traffic.


9- Register the Oracle Database Target

The target database for this lab is Oracle Database 19c at:

```text
192.168.76.132
```

Before registration, verify the listener port, database service names, container scope, and account privileges.


9.1- Verify target connectivity

On the database VM, check the listener status using the appropriate Oracle administration command:

```bash
lsnrctl status
```

Confirm the actual listener port and registered service names.

Do not assume that the PDB name is necessarily identical to its registered service name.

9.2- Prepare the target account

Follow the Oracle AVDF 20.18 target configuration instructions to prepare the account and grant the privileges required for the selected audit collection method.

Use the Oracle-provided setup scripts applicable to the target database version and trail type.

Avoid using an unrestricted administrative account as the routine collection account unless the documented procedure explicitly requires it.

 
9.3- Register the target in AVS

1. Sign in to the AVS console.
    
2. Navigate to **Targets → Register**, or the equivalent target-registration page.
    
3. Select Oracle Database as the target type.
    
4. Enter a descriptive target name.
    
5. Enter the database host IP.
    
6. Enter the verified listener port.
    
7. Enter the correct service name and required connection details.
    
8. Supply the target credentials and other requested parameters.
    
9. Test the connection.
    
10. Save the target when the connection succeeds.
    

9.4- Register the required containers

If the lab requires auditing both the CDB and its PDB, follow Oracle's documented procedure for registering each relevant container.

For this lab, the known PDB name is:

```text
ORCLPDB
```

Verify the actual service name and registration requirements before entering connection details.

10- Configure Audit Collection

Audit collection retrieves database audit records and makes them available for investigation and reporting in AVS.

This is separate from Database Firewall traffic monitoring.

10.1- Choose a supported collection method

Depending on the trail type and supported target configuration, AVDF may support:

- Audit Vault Agent-based collection.
    
- Agentless Collection for supported trail types and configurations.
    

Check the AVDF 20.18 documentation to determine which method is appropriate.

10.2- Configure the collection account and audit source

11. Run the documented target setup or privilege script.
    
12. Verify that the selected audit source is supported.
    
13. Ensure the required database auditing configuration is enabled.
    
14. Confirm that the collection account has the necessary privileges.
    
15. Resolve any target configuration errors before starting collection.
    

For Oracle Database 19c, the applicable steps depend on the selected trail type and the database's auditing configuration.

10.3- Install and activate the agent, if required

If using the Audit Vault Agent:

1. Register the relevant host in AVS.
    
2. Download the agent package generated or provided by AVS.
    
3. Install the agent on the supported host.
    
4. Follow the generated instructions to activate and configure it.
    
5. Confirm that the agent is communicating with AVS.
    
6. Associate the agent with the target as required.
    

Do not assume that installing the AVS appliance automatically installs an agent on the database host.

10.5- Add the audit trail

1. Open the registered target in AVS.
    
2. Navigate to its Audit Trails configuration.
    
3. Add an audit trail of the appropriate type.
    
4. Supply the requested trail-specific details.
    
5. Save the configuration.
    
6. Start collection explicitly.
    

10.6- Verify audit collection

Generate a controlled test event on the target database.

For example, use a permitted test account to perform a simple login or harmless SQL operation that is covered by the configured audit policy.

Then verify in AVS that:

- The audit trail is running.
    
- Collection is progressing.
    
- The test event appears in the audit records.
    
- The target, database user, event time, and action are correct.
    

If records do not appear, check the collection status, agent health, audit policies, privileges, target connectivity, and time synchronization.

11- Configure Database Firewall Monitoring

Firewall monitoring must be configured according to the actual traffic path.

11.1- Configure the monitoring point

In AVS, open the registered target and locate the Database Firewall Monitoring configuration.

Add a monitoring point using the relevant Firewall, deployment mode, interface, and target information.

The precise menu labels and fields must be confirmed against the AVDF 20.18 documentation.

11.2- Out-of-Band monitoring

For Out-of-Band monitoring:

1. Configure a supported mechanism to copy the target's SQL network traffic.
    
2. Connect the copied traffic to the correct Firewall monitoring interface.
    
3. Configure the monitoring point in AVS.
    
4. Start the monitoring point.
    
5. Generate test SQL traffic.
    
6. Confirm that the Firewall observes the expected traffic.
    

A basic VMware NAT network does not automatically mirror packets between the database and clients.

11.3- Host Monitor monitoring

For Host Monitor mode:

1. Configure the supported Host Monitor Agent on the target host.
    
2. Follow the documented procedure to capture and forward the relevant traffic.
    
3. Associate the appropriate Firewall and target settings.
    
4. Start the monitoring point.
    
5. Generate test SQL traffic.
    
6. Confirm that the Firewall receives and recognizes the traffic.
    

11.4- Proxy monitoring and blocking

For Proxy mode:

1. Configure the required Firewall network interfaces.
    
2. Configure the proxy endpoint and relevant target details.
    
3. Ensure that clients are configured to connect through the Firewall.
    
4. Test connectivity through the proxy.
    
5. Verify that the Firewall observes the SQL statements.
    
6. Configure and test security policies only after monitoring works correctly.
    

Blocking policies should initially be tested using harmless statements and noncritical test accounts.

Do not change the connection path for a production database as part of this lab exercise.


