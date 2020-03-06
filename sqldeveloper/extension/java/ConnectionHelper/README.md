# SQL Developer Examples
## ConnectionHelper
Accept connection info from the command line (and maybe on a [SocketServer](https://docs.oracle.com/javase/tutorial/networking/sockets/clientServer.html))

### Command Line
sqldeveloper -_conName_**=**_user_\[_**/**_\[_pw_]]**@**_host_**:**_port_(**:**_sid_|**/**_svc_)\[**#**_role_]

Where:
- *connName* is the name you would like for the connection
- *user* is the user name for the schema you want to use
- */password* is the password for that user *(optional - if missing e.g., user@ or user/@, SQLDeveloper will prompt for it)*
- *host* is the host that the database is on
- *port* is the port the database is listening on
- *:sid* is the sid for the database *(One of :sid or /svc MUST be supplied)*
- */svc* is the service name for the database  *(One of :sid or /svc MUST be supplied)*
- *#role* is the role  *(optional - one of SYSDBA, SYSOPER, SYSBACKUP, SYSDG, SYSKM, SYSASM if used)*

### [ConnectionHelperAddin](src/oracle/db/example/sqldeveloper/extension/connectionhelper/ConnectionHelperAddin.java)
1. Creates the requested connection in a "Transient" folder
2. Navigates to and opens the new connection
3. Sets up a hook to remove the connection when SQLDeveloper shuts down

### TODO
* Preference page _(May need/want preference page as a load trigger hook)_
  * CheckBox: Accept connection info on command line [false]
  * CheckBox: Persist command line connections [false]
* [SocketServer](https://docs.oracle.com/javase/tutorial/networking/sockets/clientServer.html)
* Preference page
  * NumericSpinner: Listener port [4444]
  * CheckBox: Autostart server
  * Button: Start now 
* Simple client test app for [SocketServer](https://docs.oracle.com/javase/tutorial/networking/sockets/clientServer.html)


