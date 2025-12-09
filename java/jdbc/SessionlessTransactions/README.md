## Overview

This project demonstrates the use of sessionless transactions feature of Oracle Database using JDBC.

The project is a web service that handles booking requests.

## Building and testing

Create a test user:

~~~SQL
CREATE USER test_user IDENTIFIED BY test_password;
GRANT CREATE SESSION TO test_user;
GRANT CREATE TABLE TO test_user;
GRANT CREATE SEQUENCE TO test_user;
GRANT DROP ANY TABLE TO test_user;
GRANT UNLIMITED TABLESPACE TO test_user;
~~~

Please set the database URL as an environment variable before running the application.

**Example:**
~~~
export TEST_DATABASE_URL=jdbc:oracle:thin:@localhost:5221:orcl
~~~

**Build and run endpoint tests:**
~~~
mvn install
~~~