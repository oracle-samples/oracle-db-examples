# Resource Providers Sample

Simple Sample Application demonstrating use of Resource Providers.

- __Oracle JDBC Version `ojdbc11-production` - `v23.5.0.24.07`__
- __Java Version used `21`__
- __Oracle Autonomous Database used `19c`__

## Environment Variables
The following environment variables are expected by the application.
In order to successfully run the application, the required environment variables below are marked and some are optional:

| Variable               |  Required   | Name                                 | Default | Description                                                                                                                         |
|------------------------|:-----------:|--------------------------------------|---------|-------------------------------------------------------------------------------------------------------------------------------------|
| `ORACLE_PASSWORD`      | Conditional | Database Password                    | -       | Database Credential if required                                                                                                     |
| `ORACLE_USERNAME`      | Conditional | Database User                        |         | Database Credentials  if required, user must exist                                                                                  |
| `COMPARTMENT_OCID`     | Conditional | Compartment OCID                     |         | Compartment Oracle Cloud Identifier(OCID) in which the Oracle Database lives in, used by Access Token Provider in determining scope |
| `DATABASE_OCID`        | Conditional | Database OCID                        |         | Database Oracle Cloud Identifier(OCID), used by multiple providers                                                                  |
| `KEY_VAULT_URL`        | Conditional | Azure Key Vault URL                  |         | Key Vault URL used by Azure Key Vault Providers                                                                                     |
| `USERNAME_SECRET_NAME` | Conditional | Azure Key Vault Username Secret Name |         | Name of secret in Azure Key Vault used by the Azure Key Vault Username Providers                                                    |
| `PASSWORD_SECRET_NAME` | Conditional | Azure Key Vault Password Secret Name |         | Name of secret in Azure Key Vault used by the Azure Key Vault Password Providers                                                    |

### Demo Files
- [demo-1.properties](properties/demo-1.properties) - Property file for OCI Connection TLS + OCI Connection String Providers
- [demo-2.properties](properties/demo-2.properties) - Property file for OCI Connection TLS + OCI Connection String + OCI Access Token Providers
- [demo-3.properties](properties/demo-3.properties) - Property file for OCI Connection TLS + OCI Connection String + Azure Key Vault Username and Password Providers




# Building the Application
The application uses Maven to build and manage the project with its dependencies.
```bash
mvn clean package
```

# Running the Application
To run the application JAR, you can run the following commmand:
```bash
java -jar target/java-basic-1.0-SNAPSHOT.jar
```

# Running the Demos

### Example 1: OCI Connection TLS + OCI Connection String Providers

To run this example, in [main.java](src/main/java/org/oracle/Main.java), set the following environment variables
referenced in the following lines, as user credentials are required. 
```java
    String PASSWORD = System.getenv("ORACLE_PASSWORD");
    String USERNAME = System.getenv("ORACLE_USERNAME");
```
Make sure the User and Password are set:
```java
OracleDataSource ods = new OracleDataSource();
ods.setURL("jdbc:oracle:thin:@");
ods.setUser(USERNAME);
ods.setPassword(PASSWORD);
```
Set the following system property to the demo-1.properties file.
```bash
    System.setProperty("oracle.jdbc.config.file", "properties/demo-1.properties");
```

This `.properties` file requires the environment variable:
- DATABASE_OCID


Refer to the following documentations in regard to authentication and further configurations:
1. [Configuring Authentication for Resource Providers](https://github.com/oracle/ojdbc-extensions/blob/main/ojdbc-provider-oci/README.md#configuring-authentication-1)
2. [OCI Connection TLS Provider](https://github.com/oracle/ojdbc-extensions/blob/main/ojdbc-provider-oci/README.md#database-tls-provider)
3. [OCI Connection String Provider](https://github.com/oracle/ojdbc-extensions/blob/main/ojdbc-provider-oci/README.md#database-connection-string-provider)

### Example 2: OCI Connection TLS + OCI Connection String + OCI Access Token Providers

To run this example, in [main.java](src/main/java/org/oracle/Main.java), __remove__ or __comment out__ the following lines as user credentials are not required.
```java
    String PASSWORD = System.getenv("ORACLE_PASSWORD");
    String USERNAME = System.getenv("ORACLE_USERNAME");
```

Make sure the credentials are NOT set:
```java
OracleDataSource ods = new OracleDataSource();
ods.setURL("jdbc:oracle:thin:@");
```

Set the following system property to the demo-2.properties file.

```bash
    System.setProperty("oracle.jdbc.config.file", "properties/demo-2.properties");
```

This `.properties` file requires the environment variable:
- DATABASE_OCID
- COMPARTMENT_OCID


Refer to the following documentations in regard to authentication and further configurations:
1. [Configuring Authentication for Resource Providers](https://github.com/oracle/ojdbc-extensions/blob/main/ojdbc-provider-oci/README.md#configuring-authentication-1)
2. [OCI Access token Provider](https://github.com/oracle/ojdbc-extensions/blob/main/ojdbc-provider-oci/README.md#access-token-provider)
3. [Authenticating into the Database using Oracle Cloud IAM and Access Tokens](https://docs.oracle.com/en/cloud/paas/autonomous-database/serverless/adbsb/manage-users-iam.html)



### Example 3: OCI Connection TLS + OCI Connection String Providers

To run this example, in [main.java](src/main/java/org/oracle/Main.java),  __remove__ or __comment out__ the following lines as user credentials are not required.
```java
    String PASSWORD = System.getenv("ORACLE_PASSWORD");
    String USERNAME = System.getenv("ORACLE_USERNAME");
```

Make sure the credentials are NOT set:
```java
OracleDataSource ods = new OracleDataSource();
ods.setURL("jdbc:oracle:thin:@");
```

Set the following system property to the demo-3.properties file.

```bash
    System.setProperty("oracle.jdbc.config.file", "properties/demo-3.properties");
```

This `.properties` file requires the environment variables:
- DATABASE_OCID
- KEY_VAULT_URL
- USERNAME_SECRET_NAME
- PASSWORD_SECRET_NAME


Refer to the following documentations in regard to authentication and further configurations:
1. [Configuring Authentication for Resource Providers](https://github.com/oracle/ojdbc-extensions/blob/main/ojdbc-provider-oci/README.md#configuring-authentication-1)
2. [Azure Key Vault Username Provider](https://github.com/oracle/ojdbc-extensions/blob/main/ojdbc-provider-azure/README.md#key-vault-username-provider)
3. [Azure Key Vault Password Provider](https://github.com/oracle/ojdbc-extensions/blob/main/ojdbc-provider-azure/README.md#key-vault-password-provider)

# Documentation
- [GitHub: Oracle JDBC Extensions](https://github.com/oracle/ojdbc-extensions/tree/main)


