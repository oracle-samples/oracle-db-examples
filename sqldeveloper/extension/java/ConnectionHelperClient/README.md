# SQL Developer Examples
## ConnectionHelperClient
A simple client for the ConnectionHelperServer. The ant _deploy target will copy the jar file to *<sqldev>*/sqldeveloper/lib/ConnectionHelperClient.jar. You can move it wherever convenient. 


### Command Line
java -jar ConnectionHelperClient.jar _connectionInfo_ \[_svrPort_]


_connectionInfo_ is -_conName_**=**_user_\[**/**\[_pw_]]**@**_host_**:**_port_(**:**_sid_|**/**_svc_)\[**#**_role_]

Where:
- *connName* is the name you would like for the connection
- *user* is the user name for the schema you want to use
- */password* is the password for that user *(optional - if missing e.g., user@ or user/@, SQLDeveloper will prompt for it)*
- *host* is the host that the database is on
- *port* is the port the database is listening on
- *:sid* is the sid for the database *(One of :sid or /svc MUST be supplied)*
- */svc* is the service name for the database  *(One of :sid or /svc MUST be supplied)*
- *#role* is the role  *(optional - one of SYSDBA, SYSOPER, SYSBACKUP, SYSDG, SYSKM, SYSASM if used)*
and<br/>
- *svrPort* is the port the ConnectionHelperServer is listening on *(optional default: 51521)*

