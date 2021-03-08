# Spring Boot Sample
This is a SpringBoot sample using Oracle JDBC and UCP to connect to Autonomous Database. The sample creates a SpringBoot application and performs different JDBC operations. 

* ALL_TABLES: Displays 20 records from the ALL_TABLES table. 
* EMP: Displays the records from EMP table. You can create EMP and other tables and populate the data using the script [JDBCSampleData.sql](https://github.com/oracle/oracle-db-examples/blob/master/java/jdbc/BasicSamples/JDBCSampleData.sql) 
* Insert into EMP: Insert a new record into the table. The new row will not be deleted. It displays all the records of EMP table and you can see the new row that was created. 

# Main Components of the code 
* **OracleJdbcAppication.java**: This is the main class where we have the methods to perform some database operations. 
* **DataSourceConfig.java**: This is the class where the datasource is created by reading the values from application.properties. We have Universal Connection Pool (UCP) as the datasource. 
* **EmployeeServiceImpl.java**: This is the bean where the business logic is present. It implements the interface EmployeeServe.java. 
* **Employee.java and AllTables.java**: These are the DAO classes represents the Model of the application. 
* **EmployeeDAOImpl.java and AllTablesDAOImpl.java**: These are the Data Access Object classes to access the data from the database. 
* **pom.xml**: Maven build script with all the necessary dependencies for the application to run. 
* **application.properties**: Contains all the database specific details such as database URL, database username, database password etc., 

## Directory Structure
```
SpringBootSample
├── Readme.md
├── pom.xml
└── src
    └── main
        ├── java
        │   └── com
        │       └── oracle
        │           └── springapp
        │               ├── DataSourceConfig.java
        │               ├── OracleJdbcApplication.java
        │               ├── dao
        │               │   ├── AllTablesDAO.java
        │               │   ├── EmployeeDAO.java
        │               │   └── impl
        │               │       ├── AllTablesDAOImpl.java
        │               │       └── EmployeeDAOImpl.java
        │               ├── model
        │               │   ├── AllTables.java
        │               │   └── Employee.java
        │               └── service
        │                   ├── EmployeeService.java
        │                   └── impl
        │                       └── EmployeeServiceImpl.java
        └── resources
            └── application.properties
```
