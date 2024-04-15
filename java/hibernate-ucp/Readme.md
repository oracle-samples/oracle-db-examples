# Hibernate UCP Sample
This is a hibernate sample that uses Universal Connection Pool(UCP). The sample creates an hibernate application and configures ucp through config/properties file.. 

# Main Components of the code 
* **HibernateUCPSample**: This is the main class where we have the methods to get a connection from UCP pool configured through the properties file. 
* **pom.xml**: Maven build script with all the necessary dependencies for the application to run. 
* **application.properties**: Contains all the database specific details such as database URL, database username, database password etc., This also contains all the properties to UCP as a datasource. 
