# SchemaPrivileges
Tutorial on Database 23c Schema Privilege grants

One of the most-requested enhancements for the Oracle Database is granting privileges to an application’s tables. Application schemas tend to change over time, and if you follow the design paradigm of separating the data-owning schema from the application service account used to access that data, then with older database versions, there were only two choices:
1.	Grant individual privileges on each table and view in the application schema
2.	Grant “* ANY” privileges – select any table, update any table and the like
The second choice is obviously sub-optimal – you are throwing the fundamental security concept of least privilege out of the window when you grant the ability to select from every table in the database!
The first choice can also be sub-optimal – when the application adds new objects to the schema, you must remember to make corresponding privilege grants that reflect those changes. 
Oracle Database 23c fixes this issue once and for all – you can still choose to do individual grants for tables and views, or * ANY system privilege grants, but 23c also introduces a new SCHEMA level grant – if you GRANT SELECT ANY TABLE ON SCHEMA HR TO BOB; then when Bob logs in he can see all tables and views in the HR schema. And if a new table is added to the schema, Bob instantly has access to that new table.
Users can grant schema level privileges on their own schema without having any special privileges. In order to grant schema-level privileges on someone else’s schema you’ll need either the new GRANT ANY SCHEMA or the GRANT ANY PRIVILEGE system privilege.
To see which schema privileges have been granted, consult the new DBA_SCHEMA_PRIVS view. There are also ROLE_SCHEMA_PRIVS, USER_SCHEMA_PRIVS, and SESSION_SCHEMA_PRIVS views.

## Tutorial
This directory includes the tutorials related to Database 23c schema privileges. The tutorial script walks you through how to grant, use, and monitor the privileges.

## Documentation

See the Database 23c Security guide [Managing Schema Privileges](https://docs.oracle.com/en/database/oracle/oracle-database/23/dbseg/configuring-privilege-and-role-authorization.html#GUID-483D04AF-BC5B-4B3D-9D9A-1D2C3CE8F12F) for details on working with schema privileges

## Discussion Forum

Please ask your questions and share your use cases with us in the [Oracle Database 23c Free – Developer Release forum](https://forums.oracle.com/ords/apexds/domain/dev-community/category/oracle-database-free).

