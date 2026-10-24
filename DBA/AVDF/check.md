# Oracle Audit Vault and Database Firewall (AVDF)

## Technical Overview, Prerequisites, Installation Plan, and Validation Checklist

Oracle Audit Vault and Database Firewall (AVDF) is a database security platform designed to centralize audit collection, monitor database SQL traffic, detect suspicious activity, enforce database security policies, and provide reports and alerts for security investigations and compliance.

**WHAT IS REALLY HAPPENING ON YOUR DATABASE?**

**WHO IS DOING WHAT ON YOUR DATABASE?**

#### What does AVDF do?

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

**Audit Vault Server:**

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
Firewall policies
        |
        |-----> Monitor
        |
        |-----> Alert
        |
        |-----> Block
        |
        |-----> Substitute SQL Statement
```

The action depends on the configured policy and the deployment mode. Blocking and SQL substitution require a supported enforcement configuration; they are not available in every monitoring deployment.

This can happen based on user session information, such as the client IP address or database username, together with SQL statement characteristics and other available session attributes.

The Database Firewall can use learned or explicitly defined SQL policies to identify normal or approved SQL activity and detect or block traffic that violates those policies. It does not automatically guarantee that every attack will be detected or that every unrecognized statement will be blocked.

**Oracle recommends combining database auditing with SQL traffic monitoring when comprehensive database activity monitoring is required.**

Auditing typically captures detailed information about database events that have occurred, while monitoring SQL traffic can analyze statements before they reach the database when the traffic passes through an appropriate monitoring or enforcement point. This makes it possible to detect suspicious statements and, in supported deployment modes, block them before execution.

---

## AVDF Components

AVDF has three main components:

1. Audit Vault Server
    
2. Audit Vault Agent
    
3. Database Firewall
    

###### Audit Vault Server

The Audit Vault Server is a mandatory component of AVDF. It is a dedicated appliance that contains:

```
Hardened Oracle Linux operating system
Oracle Database (dedicated AVDF repository)
AVDF application
```

###### Hardened Oracle Linux Operating System

In this part, we should:

- Disable unnecessary services.
    
- Restrict network access and close unnecessary ports.
    
- Apply security hardening.
    
- Restrict administrative access.
    
- Minimize the attack surface.
    

The operating system is hardened as part of the AVDF appliance design. We should follow Oracle's supported configuration and hardening procedures rather than manually modifying the underlying operating system.

###### Oracle Database

This is not a normal, general-purpose Oracle Database installation. It is a dedicated database repository used by AVDF to store and manage collected audit data and other AVDF-related information.

The repository uses security mechanisms such as Transparent Data Encryption (TDE) to protect supported data at rest. AVDF also incorporates additional security controls, depending on the version and configuration.

TDE protects encrypted database data files and other supported storage components. However, it is important to understand that TDE alone does not mean that nobody, including a DBA, can ever access the data. Access protection depends on encryption-key management, privileges, and the overall security configuration.

The repository is managed as part of the AVDF appliance, and administrators should not treat it as a regular application database.

###### AVDF Applications

The AVDF application provides the interfaces used to perform the following tasks:

```
1- View reports
2- Define and manage policies
3- View alerts
4- Manage targets
5- Monitor audit collection
6- Investigate suspicious database activities
```

This application includes:

1. Web Console
    
2. AVCLI
    

**Web Console**

We access it through a web browser to configure AVDF, manage targets, review audit records, investigate alerts, and generate reports.

**AVCLI**

AVCLI is a command-line interface used to perform supported administrative and configuration tasks through commands.

A general view of the Audit Vault Server:

```
        Audit Vault Server
        ┌────────────────────────────┐
        │                            │
        │ 1. Hardened Linux OS       │
        │                            │
        │ 2. Oracle Database         │
        │    (Audit Repository)      │
        │    - TDE Encryption        │
        │    - Additional Security   │
        │      Controls              │
        │                            │
        │ 3. AVDF Application        │
        │    - Web Console           │
        │    - AVCLI                 │
        │                            │
        └────────────────────────────┘
```

Note: Database Vault and other security mechanisms should only be listed as components of the repository when they are confirmed to be included and configured in the specific AVDF release. Do not assume that every security feature is independently configurable by the AVDF administrator.

---

###### Audit Vault Agent

The Audit Vault Agent is installed on supported target systems when required by the selected collection method.

Its main responsibilities are:

- Collect audit data from supported target systems.
    
- Transfer collected audit records securely to the Audit Vault Server.
    
- Support the configured audit collection mechanism for each target.
    
- Report collection status and related information to AVDF.
    

The agent is not necessarily required for every type of target or every collection method. Some targets use other supported collection mechanisms.

For example, when collecting database audit records, the agent works with the configured database audit source and collection settings.

A simplified workflow:

```
Target Database
      |
      |  Audit Records
      v
Audit Vault Agent
      |
      |  Secure Transfer
      v
Audit Vault Server
      |
      v
Central Audit Repository
      |
      v
Reports, Alerts, and Investigation
```

The agent collects and transfers audit information. It does not replace the native database auditing mechanism that generates the audit records.

---

###### Database Firewall

The Database Firewall monitors SQL traffic between clients or applications and supported database targets.

Its main responsibilities are:

- Analyze SQL statements and database traffic.
    
- Apply configured security policies.
    
- Monitor normal and suspicious SQL activity.
    
- Generate alerts for policy violations.
    
- Block or substitute SQL statements in supported enforcement configurations.
    

The Database Firewall can be deployed in different modes, depending on the AVDF version and architecture.

**Monitoring Mode**

In monitoring deployments, the firewall analyzes visible SQL traffic and generates events or alerts according to its configuration. It does not necessarily block the traffic.

**Proxy Mode**

In supported Proxy-mode deployments, traffic passes through the Database Firewall. This allows it to enforce configured policies, including blocking or substituting SQL statements when supported.

A simplified workflow:

```
Client / Application
        |
        v
Database Firewall
        |
        |-----> Analyze SQL Traffic
        |
        |-----> Apply Security Policies
        |
        |-----> Generate Alerts
        |
        |-----> Block / Substitute
        |       (when supported)
        |
        v
Target Database
```

The exact architecture depends on whether the deployment uses monitoring or an enforcement configuration.

---

## AVDF Prerequisites

Before installing AVDF, we must verify the following prerequisites.

**1. Hardware and Virtualization**

- Verify that the server or virtual machine meets the hardware requirements for the selected AVDF release.
    
- Check CPU, memory, storage capacity, and supported virtualization platforms.
    
- Ensure that the required storage is available for the Audit Vault Server and Database Firewall appliances.
    

**2. Network Configuration**

- Assign the required IP addresses.
    
- Configure the hostname and DNS settings.
    
- Verify network connectivity between AVDF components and target systems.
    
- Check routing, firewall rules, and required communication ports.
    
- Ensure that the required time synchronization is configured.
    

**3. Installation Media**

- Download the correct AVDF installation image for the intended release.
    
- Verify the supported installation procedure and release-specific requirements.
    
- Confirm that the installation media is complete and has passed any required integrity checks.
    

**4. Target Databases**

- Identify the databases that will be registered as targets.
    
- Verify that each target is supported by the selected AVDF release.
    
- Determine the required database audit configuration.
    
- Prepare the necessary accounts and privileges for audit collection.
    
- Verify connectivity between the target databases and the AVDF collection components.
    

**5. Security and Access**

- Define the administrative accounts and access responsibilities.
    
- Prepare the required certificates or secure communication settings when applicable.
    
- Restrict access to the AVDF management interfaces.
    
- Follow Oracle's supported appliance security and hardening procedures.
    

The exact hardware specifications, ports, supported platforms, and account privileges must be verified against the documentation for the specific AVDF release.

---

## AVDF Installation Plan

The installation process can be divided into the following phases.

**Phase 1: Prepare the Environment**

- Verify hardware or virtualization requirements.
    
- Configure the network.
    
- Prepare installation media.
    
- Confirm that all prerequisites are satisfied.
    

**Phase 2: Install the Audit Vault Server**

- Install the Audit Vault Server using the supported installation procedure.
    
- Configure the required network settings.
    
- Complete the initial setup.
    
- Verify that the server is accessible through the Web Console.
    

**Phase 3: Install the Database Firewall**

- Install the Database Firewall appliance.
    
- Configure the required network interfaces and connectivity.
    
- Register or configure the Database Firewall in AVDF as required by the selected release.
    
- Verify communication between the appliances.
    

**Phase 4: Configure the Audit Vault Agent**

- Install the agent on supported target systems where required.
    
- Register or activate the agent with the Audit Vault Server.
    
- Verify that the agent is communicating successfully.
    

**Phase 5: Add and Configure Targets**

- Register the target databases in AVDF.
    
- Configure the required collection settings.
    
- Configure database auditing and the required audit sources.
    
- Verify that AVDF can collect audit records from each target.
    

**Phase 6: Configure Database Firewall Policies**

- Configure the traffic monitoring architecture.
    
- Define trusted paths and relevant session attributes.
    
- Configure SQL statement and database object policies as required.
    
- Define the actions for policy violations.
    
- Test monitoring and enforcement behavior in a controlled environment.
    

**Phase 7: Validate the Deployment**

- Generate test audit events.
    
- Verify that audit records appear in AVDF.
    
- Test alert generation.
    
- Verify Database Firewall monitoring.
    
- Test blocking or SQL substitution only when the deployment supports these actions.
    
- Document the results.
    

---

## AVDF Validation Checklist

After installation, we should validate the environment to ensure that every component works correctly.

### Audit Vault Server

- The Audit Vault Server is running.
    
- The Web Console is accessible.
    
- Administrative login works correctly.
    
- The configured network settings are correct.
    
- The server can communicate with the required AVDF components.
    

### Audit Vault Agent

- The agent is installed where required.
    
- The agent is registered or activated successfully.
    
- The agent can communicate with the Audit Vault Server.
    
- Audit collection is configured correctly.
    
- Test audit records are collected and transferred successfully.
    

### Target Databases

- The target databases are registered in AVDF.
    
- The target credentials and collection privileges are configured correctly.
    
- Database auditing is enabled and configured for the required events.
    
- Test login events are generated.
    
- Test DDL and DML events are generated.
    
- The expected audit records appear in AVDF.
    

### Database Firewall

- The Database Firewall is configured and operational.
    
- The monitoring architecture is working as intended.
    
- SQL traffic from the test client is visible to the firewall.
    
- The configured policies are applied to the expected traffic.
    
- Alerts are generated for the defined test violations.
    
- Blocking or SQL substitution works as expected in supported enforcement configurations.
    

### Reports and Alerts

- Audit records can be searched and reviewed.
    
- Alerts are generated for the configured test scenarios.
    
- Reports display the expected audit information.
    
- The collected information can be used to identify who performed an operation, what was performed, and when it occurred.
    

### Final Validation

- All critical components are operational.
    
- Audit collection has been verified end to end.
    
- Database Firewall monitoring has been verified end to end.
    
- Enforcement behavior has been tested where applicable.
    
- The results and any remaining issues have been documented.
    

**Final Goal**

At the end of the installation and validation process, we should be able to answer these questions:

- **WHO** accessed the database?
    
- **WHAT** did they do?
    
- **WHEN** did the activity happen?
    
- **WHERE** did the connection come from?
    
- **WAS** the activity allowed, monitored, or blocked according to the configured policies?
    

This is the main purpose of combining database auditing with SQL traffic monitoring in Oracle AVDF.