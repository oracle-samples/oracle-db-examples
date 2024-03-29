# CloudBank
### (Oracle Sagas based demo web application)

# About

## Overview

This project showcases a demo web application that demonstrates the power and flexibility of Oracle Sagas in distributed transaction management. Oracle Sagas provide a robust mechanism for maintaining data consistency across microservices in a distributed system, allowing for complex business transactions to be executed atomically. This Java application utilizes [Oracle Saga and Microprofile LRA](https://docs.oracle.com/en/database/oracle/oracle-database/23/adfns/developing-applications-saga.html#GUID-D6E883B8-96F2-4364-B564-843465DFF5CF) based annotations to bind Java methods to Oracle Saga entities (Initiators and Participants), facilitating the management of distributed transactions with ease and reliability.

## Key Features

- **Oracle Saga Integration**: Leverages Oracle Sagas for managing distributed transactions, using annotations under the [Oracle Saga Maven dependency](https://mvnrepository.com/artifact/com.oracle.database.saga) to link Java methods to saga participants and initiators.
- **Distributed Transaction Scenarios**: Implements three primary saga workflows for creating bank accounts, issuing credit cards, and transferring money, showcasing various aspects of distributed transactions, including compensations and rollbacks.
- **CloudBank Coordinator**: Acts as a saga initiator, orchestrating transactions across multiple participants with logic to commit or rollback based on the outcome of participant actions.
- **Participants**: Includes BankA, BankB, and CreditScore as participants in the saga transactions, demonstrating intra and interbank operations.
- **Lock-Free Reservations**: Utilizes Oracle Reservable columns for lock-free reservations, enhancing performance and eliminating the need for manual compensation in interbank transfers. [Learn more about Oracle Reservable columns](https://docs.oracle.com/en/database/oracle/oracle-database/23/adfns/using-lock-free-reservation.html#GUID-60D87F8F-AD9B-40A6-BB3C-193FFF0E60BB).
- **Frontend Application**: Features a python flask based frontend for creating new customers, logging in, and facilitating the process of account creation, credit card issuance, and money transfers, complete with a real-time status update dashboard.

## Saga Processes

1. **Bank Account Creation Saga**: This saga showcases the application's capability to execute straightforward yet essential transactions involving fewer participants. The process initiates with the CloudBank Coordinator, which acts as the saga initiator, launching a request to create a new bank account, which could be either a Checking or Savings account. This request is directed to one of the participant services, such as BankA or BankB, based on predefined logic or customer preference.

    - The designated account service attempts to create the new account. Success or failure of this operation determines the saga's next step.
    - On successful account creation, the saga commits the transaction, officially registering the new account in the system.
    - If the operation fails, the saga triggers a rollback, ensuring no partial or incomplete transaction data remains in the system.

   This process exemplifies the use of sagas for single-participant transactions beyond the initiator, emphasizing atomicity and consistency in the system's state.


2. **Credit Card Issuance Saga**: This process is a comprehensive demonstration of the application's ability to handle multistep, multi-participant transactions. It begins with the CloudBank Coordinator initiating a saga to issue a new credit card. The saga unfolds in several stages:
    - First, the initiator requests one of the banks (either BankA or BankB) to set up a new credit_card account for the customer.
    - Concurrently, a request is sent to the CreditScore service to assess the customer's creditworthiness.
    - Upon receiving the credit score, the CloudBank Coordinator evaluates it to decide whether to proceed. If the criteria are met, it instructs the relevant account service to update the customer's account balance, effectively setting the stage for the new credit card's issuance.

   This entire operation is encapsulated within a single saga, ensuring that either all steps succeed together, thereby committing the transaction, or fail as a unit, in which case the saga orchestrates a rollback to maintain data integrity and consistency across the system.


3. **Money Transfer Saga**: This complex saga illustrates the application's adeptness in handling transactions that span multiple banks and involve intricate coordination between participants. The CloudBank Coordinator again takes the lead, initiating a saga to transfer money between two accounts, which may reside within the same bank (intra-bank) or across different banks (inter-bank).

    - In case of interbank transfer,
    - The saga begins with simultaneous requests for withdrawal from one account and deposit into another. These operations are managed by the respective banks, BankA or BankB, depending on the accounts' locations.
    - Oracle's Reservable columns play a crucial role here, facilitating lock-free reservations that enhance the efficiency of interbank transfers. This eliminates the need for manual compensations, even in the complex scenario of interbank transactions.
    - The saga monitors the success of both withdrawal and deposit operations. Only when both operations succeed does the saga commit the transaction, ensuring the transfer is reflected accurately across accounts.
    - In case of a failure in either operation, the saga orchestrates a comprehensive rollback. This includes automatically undoing any partial transactions to maintain the integrity and consistency of account balances across bank.

   The Money Transfer Saga exemplifies the application's capability to manage high-complexity transactions, showcasing sophisticated coordination and rollback mechanisms to guarantee data consistency and integrity, even in scenarios of network or system failures.

## Getting Started

This section guides you through all the prerequisites and steps needed to get this project up and running, including initial database setup, SAGA_WALLET creation, backend and frontend configuration.

### Prerequisites

Before starting the installation process, ensure the following prerequisites are met:
1. **Java Development Kit (JDK)** is installed for running the Java application.
2. **Python** is installed for the Flask frontend.
3. **Maven** is installed for Java project dependency management.
4. **Tomcat 10** is installed for the WAR deployment.
5. Environment variable `CATALINA_HOME` set to the Tomcat top-level directory.
6. **Oracle DB 23C** is installed and operational, accessible via a running DB listener with an exposed port. This database version supports the advanced features used by the application, including Oracle Sagas.
7. The `requirements.txt` file is present for Python dependencies, which can be installed using pip.

### Initial Database Setup

1. **Create SAGA_WALLET**:
    - If the Java application and Oracle DB are on the same server, create a SAGA_WALLET using scripts similar to `saga_wallet_example/setup_wallet.sh`. Make sure to have a wallet.txt file which holds the passwords for the wallet similar to `saga_wallet_example/wallet.txt`. 
    - Specify the wallet path and `tnsnames.ora` path in `application.properties` under `src/main/resources`. The script can be executed in the following way from the respective directories:
   ```
   ./setup_wallet.sh
   ```
    - If deploying the Java application on a different server than the Oracle DB, create the wallet on the Oracle DB server, then export it to the server running Java application. Provide the wallet's and tnsnames.ora path in `application.properties`. The `tnsnames.ora` looks something like the file found on `saga_wallet_example/tnsnames.ora`.

2. **Execute SQL Scripts**:
    - The database needs to be prepared before the maven application can be deployed. The application assumes:
   ```
    - CloudBank Coordinator (Initiator, Saga coordinator and Broker) deployed over cdb1_pdb1.
    - BankA (Participant) deployed over cdb1_pdb2.
    - BankB (Participant) deployed over cdb1_pdb3.
    - CreditScore (Participant) deployed over cdb1_pdb4.
   ```
    -  Modify `setupPDBS.sql` to match your CDB details, specifically, change `<seed_database>` on the `create pluggable database` lines to the value of your seed database. 
    -  Copy `initdb.sh.example` to `initdb.sh` and mark it as executable, i.e. `chmod a+x ./initdb.sh`
    -  Modify `initdb.sh` with the correct credentials and connection strings for the environment. To (re)initialize the database, run
    -  NOTE: The 'setupPDBS.sql' script initially drops PDB's (cdb1_pdb1,cdb1_pdb2,cdb1_pdb3 and cdb1_pdb4) before recreating them.
    ```
    ./initdb.sh
   ```
    - The initdb.sh further automatically executes PDB specific scripts to set up respective Saga entities and their supporting tables.
    - **Note**: 
      - `sqlplus` is required and must be in your path.
      - The tnsnames.ora should include the newly created PDB's CDB1_PDB1, CDB1_PDB2, CDB1_PDB3 and CDB1_PDB4.
      
    

### Backend and Frontend Setup

#### Backend Setup

The backend service utilizes Java and Maven for dependency management. Follow the setups below for backend setup, including environment preparation and running the application.

1. The application is split into 4 components:
   - The CloudBank Coordinator is a WAR that needs to be deployed into a Tomcat 10 container. 
   - The BankA is also a WAR that needs to be deployed into a Tomcat 10 container.
   - The BankB is also a WAR that needs to be deployed into a Tomcat 10 container.
   - The CreditService is also a WAR that needs to be deployed into a Tomcat 10 container. 

2. Deployment Guide: 
   - Ensure that your Apache Tomcat server is running. You can start Tomcat by executing the `startup.sh` script (on Unix/Linux) or `startup.bat` script (on Windows) located in `$CATALINA_HOME/bin` directory.
   - Follow these instructions to deploy BankA, BankB, CreditScore, and finally, the CloudBank applications.
      - Build WAR files:
        1. Run `mvn clean install` from the `bankA` directory, it will copy the properties file as well as build and package this application in WAR format.
        2. Run `mvn clean install` from the `bankB` directory, it will copy the properties file as well as build and package this application in WAR format.
        3. Run `mvn clean install` from the `creditscore` directory, it will copy the properties file as well as build and package this application in WAR format. 
      - Deploy `bankA.war`, `bankB.war`, `creditscore.war` over Tomcat.
          1. Locate the WAR files for BankA, BankB and CreditScore in their respective `target` directories.
          2. Copy each WAR file into the `$CATALINA_HOME/webapps` directory to initiate the deployment.
          3. Once deployed, Tomcat will automatically extract the WAR files into corresponding directories under `webapps`.
      - Configuring Participant URLs in CloudBank Application.
          1. Open the `Stubs.java` file at `src/main/java/com/oracle/saga/cloudbank/stubs/Stubs.java`.
          2. Update the participant URLs (<BANKA_URL:PORT>, <BANKB_URL:PORT> and <CREDITSCORE_URL:PORT>) to match the endpoints exposed by Tomcat after deployment.
      - Compiling and Deploying CloudBank Application.
          1. Run `mvn clean install` from the `cloudbank` directory, it will copy the properties file as well as build and package this application in WAR format.
          2. Copy the generated `cloudbank.war` file into the `$CATALINA_HOME/webapps` directory.
          3. Tomcat will automatically deploy the application and make it available.
        
3. Deployment Verification:
    - After deploying all components, verify that each application is accessible via its context path on the Tomcat server.
      1. To verify cloudbank deployment visit, `<TOMCAT_URL:PORT>/cloudbank/version`, it should reflect `1.0`.
      2. To verify bankA deployment visit, `<TOMCAT_URL:PORT>/bankA/version`, it should reflect `1.0`.
      3. To verify bankB deployment visit, `<TOMCAT_URL:PORT>/bankB/version`, it should reflect `1.0`.
      4. To verify creditscore deployment visit, `<TOMCAT_URL:PORT>/creditscore/version`, it should reflect `1.0`.
    - You can access the Tomcat Web Application Manager to see the list of deployed applications and their statuses.
    - For detailed information on managing and monitoring your Tomcat server, refer to the [Tomcat documentation](https://tomcat.apache.org/tomcat-10.0-doc/manager-howto.html).

4. Deployment Troubleshooting:
   - If you encounter issues during the deployment process, consult the Tomcat logs located in `$CATALINA_HOME/logs` for error messages and debugging information. Common issues include port conflicts, missing dependencies, and configuration errors in the deployment descriptors.
   - If you encounter issues related to `$CATALINA_HOME` not being defined, it means the environment variable pointing to your Tomcat installation directory has not been set. This variable is crucial for running Tomcat commands and scripts.
   - If tomcat is running as tomcat user make sure it has access to file in saga_wallet.


#### Frontend Setup

The frontend is built with Python Flask. Ensure Python and pip are installed, then install the necessary dependencies from `requirements.txt`.
The dependencies can be installed using the command:
```
pip install -r requirements.txt
```

1. Modify the app.py file to update the app.secret_key and the CLOUDBANK application URL's. (deployed above)
2. Run the application using the following command:
> python app.py
3. The default port of deployment will be 5000.


#### DEMO LOGIN
There are two pre-defined Accounts in Bank A and Bank B each:
There credentials are:

| USERNAME  | PASSWORD | BANK   | OSSN    | NAME       |
|-----------|----------|--------|---------|------------|
| ORACLE001 | cb1      | Bank A | OSSN001 | CUSTOMER 1 |
| ORACLE002 | cb2      | Bank B | OSSN002 | CUSTOMER 2 |
| ORACLE003 | cb3      | Bank B | OSSN003 | CUSTOMER 3 |
| ORACLE004 | cb4      | Bank A | OSSN004 | CUSTOMER 4 |

For creating new users, make sure to add their unique OSSN, Name and Credit Score to the `credit_score_db` table in `CDB1_PDB4` (similar to `sql-script/creditscore.sql`).  


## CLEANUP 
1. Exit the python flask application.
2. Stop the tomcat server.
3. To clean up the database, modify and execute the script cleanup.sh
