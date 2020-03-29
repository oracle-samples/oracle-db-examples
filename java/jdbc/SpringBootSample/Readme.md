# Spring Boot Sample
This is a SpringBoot sample using Oracle JDBC and UCP to connect to Autonomous Database. The sample creates a SpringBoot application and performs different JDBC operations. 
(a)

# Main Components of the code 
* **OracleJdbcAppication.java**: This is the main class where we have the methods to perform some database operations. 
* **DataSourceConfig.java**: This is the class where the datasource is created by reading the values from application.properties. 
* **EmployeeServiceImpl.java**: This is the bean where the business logic is present. It implements the interface EmployeeServe.java. 
* **Employee.java and AllTables.java**:
* **EmployeeDAOImpl.java and AllTablesDAOImpl.java**: These are the Data Access Object classes to access the data from the database. 
* **

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
