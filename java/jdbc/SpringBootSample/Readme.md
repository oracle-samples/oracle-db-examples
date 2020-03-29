# SpringBootSample
This is a Jdbc sample using Oracle UCP in SpringBoot. The sample creates a SpringBoot application and performs different JDBC operations.

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
