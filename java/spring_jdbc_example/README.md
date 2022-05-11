# SpringBoot JDBC Code Sample

This is the code sample that accompanies the "Getting Started with SpringBoot & JDBC" 
video. This showcases using JDBC with UCP in a simple application, utilizing JPA to 
retrieve the data from the Autonomous Database.

# Main Components of the Code

* TestController.java: Has one get mapping that uses StudentService to retrieve all the Students
* Student.java: Models the Student class to the Students table in the database
* StudentRepository.java: Extends JpaRepository to utilize built-in queries
* StudentService.java: Implements one method that retrieves all students
* application.properties: provides database connection information along with UCP

