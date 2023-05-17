# [SQL Developer](http://www.oracle.com/technetwork/developer-tools/sql-developer/) Examples
## Extensions
You can add new folders and nodes to navigators, new actions on objects (*or sets of them*), and new editors or viewers.

Depending on requirements, this can be done in either XML or java and deployed by simply copying an XML file to the appropriate directory, or creating an extension jar -- or *check for updates* bundle for XML and/or java.

### New

* [WorksheetAction](java/WorksheetAction)
How to add actions to the worksheet context menu and / or toolbar; execute the action directly or in a background task; and present advanced / detailed information in a result panel.

* [Managing Extensions](./ManagingExtensions.md) - ([Issue 113](https://github.com/oracle/oracle-db-examples/issues/113)) How to add, disable, and remove extensions.

* [ConnectionHelper](java/ConnectionHelper)
Optionally accept connection info from the command line and/or on a [SocketServer](https://docs.oracle.com/javase/tutorial/networking/sockets/clientServer.html)

* [ConnectionHelperClient](java/ConnectionHelperClient)
A simple command line client for the ConnectionHelper socket server.


### Contents

* [Set Up / Tutorial](./setup.md) - A step by step guide to building your first extension and check for updates bundle.


* [Managing Extensions](./ManagingExtensions.md) - How to add, disable, and remove extensions.


* ["Simple" User Extensions (XML)](xml)


* [XML Based Favorites Example](xml/favorites)


* [Standard Extensions (java)](java)


* [Check For Updates (cfu)](cfu)


### External Resources
Please note these are links to external resources. They are not supplied or supported by Oracle.

* [Example Update Center](https://github.com/bjeffrie/sqldev-update-center) (external) with pre-built cfu bundles for these examples. 

* Philipp Salvisberg's [Example-based tutorials](https://github.com/PhilippSalvisberg/sqldev) to extend SQL Developer functionality. (external)

