# SpringBoot JDBC Code Sample

This is the code sample that accompanies the "Getting Started with SpringBoot & JDBC" 
video. This showcases using JDBC with UCP in a simple application, utilizing JPA to 
retrieve the data from the Autonomous Database.

# Main Components of the Code

* TestController.java: TestController.java is the RestController that maps the public endpoints to the students table. In this case, it maps '/students' to a list of all students.
* Student.java: Models the Student class to the Students table in the database.
* StudentRepository.java: Extends JpaRepository to utilize built-in queries.
* StudentService.java: Implements one method that retrieves all students.
* application.properties: Provides database connection information along with UCP connection information

