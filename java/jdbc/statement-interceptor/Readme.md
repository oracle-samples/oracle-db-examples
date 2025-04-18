# SQL Statement Interceptor example.

This is the home of the SQL statement interceptor project. It is composed of two subprojects: 
 - The interceptor (*interceptor*), a library that leverages 23ai JDBC driver features to intercept statements
 - The web demo application (*demo-app*), a SpringBoot application that demonstrates the interceptor capabilities

The interceptor subproject is standalone and so can be built and run separately. The demo application requires the interceptor project binaries.

Please see subprojects Readme.md files for further details. 

## Build the projects.

Both subprojects are included here. You can choose to run tasks from here or to 
go one level down to subproject you are interested in. 

To run the demo application from here, issue the following command
> ./gradlew :demo-app:bootRun
 
Before doing that, make sure you have properly specified datasource information (see *Running the application* section in demo-app readme file)

