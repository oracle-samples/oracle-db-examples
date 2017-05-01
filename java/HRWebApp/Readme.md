# Overview of the HR Web Application 
 
**HR Web Application** is the Java application that uses Oracle Java Database Connectivity (JDBC), Universal Connection Pool (UCP), and Oracle Java in the Database (OJVM) with Oracle Database 12c Release 2. 

It is a light weight web application that uses the MVC (Model, View, Controller) architecture and all the latest tools and technologies.  The presentation layer uses HTML that internally uses JavaScript, JQuery, and CSS to display the results.  The controller will be a servlet that talks to the Oracle Database through the Java Beans.  Maven is used for building the application. The Architecture of the HR Web Application is depicted in the following figure. 

![Architecture of HR Web Application](https://github.com/oracle/oracle-db-examples/blob/master/java/HRWebApp/HRWebApp_Architecture.jpg)

This Java application leverages HR schema and Employees table of the Oracle Database 12c Release 2.  It is intended to help the HR team of AnyCo Corporation to store the details of all the employees, add any new employee, update the employee details, delete any employee, or provide a salary hike to all employees.  There are two users **HRStaff** and **HRAdmin** who have different privileges and access to the application. 

**HRStaff** has read access to the application and do not have any privileges to update/delete an employee record.  HRStaff has privileges to perform the following functions. 

* **List All Employees** : 
This functionality retrieves information about the employees. It lists the employee information such as Employee_ID, First_Name, Last_Name, Email, Phone_Number, Job_Id, and Salary. 

* **Search By Employee ID:** : 
Use Employee ID that is the primary key of Employees table to search for a particular employee.

**HRAdmin** has a full control on the application and has both read and update privileges.  HRAdmin has access to all functionalities of the application.  HRAdmin can do the following functions in addition everything that HRStaff can do. 

* **Update Employee Record:** : 
Search for a particular employee based on the name of the employee. You can then update employee details in the record, such as first_name, last_name, email, phone_number, job_id and salary using this function.

* **Delete an Employee Record:** : 
Search for a particular employee record to be deleted using **Search by Employee ID** functionality and then, use the DELETE function to the delete the entire employee record. 

* **Increment Salary:** : 
Through this functionality, you can alter (increase or decrease) the percentage of the salary hike. A business logic to distribute this salary hike is executed through a stored procedure using Java in the database. 









