# Spring Boot Sample
This is a SpringBoot sample that uses Oracle JDBC and UCP to connect to Autonomous Database (ATP/ADW). The sample creates a SpringBoot application and performs different JDBC operations. 

* ALL_TABLES: Displays 20 records from the ALL_TABLES table. 
* EMP: Displays the records from EMP table. You can create EMP and other tables and populate the data using the script [JDBCSampleData.sql](https://github.com/oracle/oracle-db-examples/blob/master/java/jdbc/BasicSamples/JDBCSampleData.sql) 
* Insert into EMP: Insert a new record into the table. The new row will not be deleted. It displays all the records of EMP table and you can see the new row that was created. 

# Main Components of the code 
* **OracleJdbcAppication.java**: This is the main class where we have the methods to perform some database operations. 
* **EmployeeServiceImpl.java**: This is the bean where the business logic is present. It implements the interface EmployeeService.java. 
* **Employee.java and AllTables.java**: These are the DAO classes that represent 'Model' of the application. 
* **EmployeeDAOImpl.java and AllTablesDAOImpl.java**: These are the Data Access Object classes to access the data from the database. 
* **pom.xml**: Maven build script with all the necessary dependencies for the application to run. 
* **application.properties**: Contains all the database specific details such as database URL, database username, database password etc., This also contains the properties to UCP as a datasource. Make sure to have Oracle JDBC 21c driver in the class path to use UCP as a datasource. 

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
