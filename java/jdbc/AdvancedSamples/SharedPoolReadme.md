
## Pre-requisites for using a 'Shared Pool':
1. Oracle Database 12c Release 2 (12.2)
2. Oracle JDBC driver 12.2 (ojdbc8.jar)
3. UCP 12.2 (ucp.jar)
4. JDK8

## Shared pool configuration Steps :

# Shared pool works ONLY when it is configured with a common user (user starting with C##) and satisfies the following requirements.
1. Common user should have the privileges to create session, alter session and set container.
2. Common user should have execute permission on 'dbms_service_prvt' package.
3. Any specific roles or password for common user should also be specified in the UCP XML config file.

# The shared pool sample code is using a Multi-tenant database environment with one CDB and two PDBs.
1. The code is using a CDB service name of 'cdb_root_app_service_name' and PDB service names of 'pdb1_app_service_name' and 'pdb2_app_service_name'.
2. You need to create these services in your database on respective CDBs and PDBs.
3. The services configured for tenants must be an application service. Also, services must be homogeneous (should have similar properties wrt AC, TG, DRCP etc.).

# Create a common user and services as described above in your multi-tenant database and replace them in the SharedPoolCodeSample.xml file.

# Create the table - tenant1_emp on tenant1 PDB and tenant2_emp on tenat2 PDB using below SQL queries.

CREATE TABLE tenant1_emp(empno NUMBER(4,0), ename VARCHAR2(10), job VARCHAR2(9), sal NUMBER(7,2), CONSTRAINT pk_emp PRIMARY KEY (empno));
INSERT INTO tenant1_emp VALUES (7782, 'CLARK', 'MANAGER', 2450);
INSERT INTO tenant1_emp VALUES (8180, 'JONES', 'ANALYST', 2050);
INSERT INTO tenant1_emp VALUES (8543, 'FORD', 'CLERK', 2150);
INSERT INTO tenant1_emp VALUES (8765, 'SMITH', 'MANAGER', 1000);
INSERT INTO tenant1_emp VALUES (9847, 'ALLEN', 'ANALYST', 2000);
COMMIT;

CREATE TABLE tenant2_emp(empno NUMBER(4,0), ename VARCHAR2(10), job VARCHAR2(9), sal NUMBER(7,2), CONSTRAINT pk_emp PRIMARY KEY (empno));
INSERT INTO tenant2_emp VALUES (1245, 'WARD', 'SALESMAN', 1450);
INSERT INTO tenant2_emp VALUES (3572, 'MARTIN', 'MANAGER', 2050);
INSERT INTO tenant2_emp VALUES (4533, 'TURNER', 'CLERK', 2150);
INSERT INTO tenant2_emp VALUES (3127, 'ADAMS', 'PRESIDENT', 8000);
INSERT INTO tenant2_emp VALUES (2276, 'JAMES', 'ANALYST', 2000);
COMMIT;

# Make sure XML configuration file referred in code sample is present in the location specified by the URI.
 Update the XML file location URI value in JAVA program to point it to correct location. 
 Change the user name, password, service names, URL according to your database setup.

# Compile and Run the SharedPoolSampleCode.java class using JDK8.

javac SharedPoolSampleCode.java
java SharedPoolSampleCode




