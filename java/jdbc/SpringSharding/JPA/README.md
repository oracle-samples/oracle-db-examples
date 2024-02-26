## Overview

This project demonstrates the use of the latest sharding [feature](https://github.com/spring-projects/spring-framework/pull/31506) in Spring Framework with the Oracle Database.
The feature is about supporting direct routing to sharded databases.

This version uses Spring Data JPA (Hibernates), for data access.

You can use the datasource configurations provided in this project as a template for setting up the sharding feature in your own projects.

## Configuration

### Database

You can refer to the [Oracle Docs](https://docs.oracle.com/en/database/oracle/oracle-database/21/shard/sharding-deployment.html#GUID-F99B8742-4089-4E77-87D4-4691EA932207)
to learn how to set up and deploy an Oracle sharded database.
You can also refer to [Oracle Database Operator](https://github.com/oracle/oracle-database-operator) that makes deploying a sharded database on a Kubernetes Cluster an easy process.

After your sharded database is set, connect to the shard catalog as sysdba and create the demo application schema user.

~~~SQL
ALTER SESSION ENABLE SHARD DDL;

-- Create demo schema user
CREATE USER demo_user IDENTIFIED BY demo_user;
GRANT CONNECT, RESOURCE TO demo_user;
GRANT CREATE TABLE TO demo_user;
GRANT UNLIMITED TABLESPACE TO demo_user;

-- Create tablespace
CREATE TABLESPACE SET TS1 USING TEMPLATE (
    DATAFILE SIZE 10M AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED
    EXTENT MANAGEMENT LOCAL SEGMENT SPACE MANAGEMENT AUTO);
~~~

On the shard catalog connect as demo_user and run the following SQL script to create your tables.

~~~SQL
ALTER SESSION ENABLE SHARD DDL;

CREATE SHARDED TABLE users (
    user_id  NUMBER PRIMARY KEY,
    name     VARCHAR2(100),
    password VARCHAR2(255),
    role     VARCHAR2(5),
CONSTRAINT roleCheck CHECK (role IN ('USER', 'ADMIN')))
TABLESPACE SET TS1 PARTITION BY CONSISTENT HASH (user_id);

CREATE SHARDED TABLE notes (
    note_id NUMBER NOT NULL,
    user_id NUMBER NOT NULL,
    title   VARCHAR2(255),
    content CLOB,
CONSTRAINT notePK PRIMARY KEY (note_id, user_id),
CONSTRAINT userFK FOREIGN KEY (user_id) REFERENCES users(user_id))
PARTITION BY REFERENCE (UserFK);

CREATE SEQUENCE note_sequence INCREMENT BY 1 START WITH 1 MAXVALUE 2E9 SHARD;
~~~

Make sure to insert a user or two in the database before testing the application.

~~~SQL
INSERT INTO users VALUES (0, 'user1', LOWER(STANDARD_HASH('user1', 'SHA256')), 'USER');
INSERT INTO users VALUES (1, 'admin', LOWER(STANDARD_HASH('admin', 'SHA256')), 'ADMIN');
COMMIT;
~~~

To uninstall and clean up the preceding setup, you can connect as sysdba and run the following SQL script.

~~~SQL
ALTER SESSION ENABLE SHARD DDL;

DROP USER demo_user CASCADE;
DROP TABLESPACE SET TS1;
~~~

## Building the application
To build the application run:

~~~
mvn install
~~~

## Running the application

Before running the application set the following environment variables or update [application.properties](src/main/resources/application.properties). These configure the URL and credentials for the catalog database and shard director (GSM) used by the application.

~~~shell
export CATALOG_URL="the catalog url"
export CATALOG_USER="demo_user"
export CATALOG_PASS="demo_user"
export SHARD_DIRECTOR_URL="the shard director url"
export SHARD_DIRECTOR_USER="demo_user"
export SHARD_DIRECTOR_PASS="demo_user"
~~~

Then you can run the application using:

~~~shell
mvn spring-boot:run
~~~
