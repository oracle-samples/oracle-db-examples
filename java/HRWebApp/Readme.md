# Overview of the HR Web Application 
 
**HR Web Application** is the Java application that uses Oracle Java Database Connectivity (JDBC), Universal Connection Pool (UCP), and Oracle Java in the Database (OJVM) with Oracle Database 12c Release 2. 

It is a light weight web application that uses the MVC (Model, View, Controller) architecture and all the latest tools and technologies.  The presentation layer uses HTML that internally uses JavaScript, JQuery, and CSS to display the results.  The controller will be a servlet that talks to the Oracle Database through the Java Beans.  Maven is used for building the application. 

![Architecture of the HR Web Application] (/Users/nbsundar/Desktop/C/Nirmala/Java2DayGuide/java2d-guide-architecture-diagramv2.jpg)

This Java application leverages HR schema and Employees table of the Oracle Database 12c Release 2.  It is intended to help the HR team of AnyCo Corporation to store the details of all the employees, add any new employee, update the employee details, delete any employee, or provide a salary hike to all employees.  It has two users **HRStaff** and **HRAdmin** who have different roles and access to the application. 



The application has the following functionalities. 

* **List All Employees** : 
** add any new employee, update the employee details, delete any employee, or provide a salary hike to all employees.  The application will have two users “HRStaff” and “HRAdmin” who have different roles and access to the application.


