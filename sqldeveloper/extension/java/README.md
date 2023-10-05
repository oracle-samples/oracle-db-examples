# SQL Developer Examples
## Standard Extensions (java)
Standard extensions are jar files with an [OSGi](https://en.wikipedia.org/wiki/OSGi) manifest and an extension.xml defining the extension and how it integrates with SQL Developer.

[Set up your environment](../setup.md). If using the eclipse project, also modify paths in *SQLDeveloper18.1.userlibraries* and import into eclipse.

* [packaged XML](../xml/packaged)  
XML Examples packaged as an extension.jar  

* [DependencyExample](DependencyExample) 
An example editor and viewer for object dependency graphs.

* [DumpObjectTypesAction](DumpObjectTypesAction)
A quick object action to dump the list of connection / objects types as INFO message in the log window. Plus one to show the selected object's connection / object type.

* [ContextMenuAction](ContextMenuAction)
A quick context menu action on FUNCTION, PROCEDURE code editor to insert a static string and
a PLDoc template if PL/Scope information is available.

* [InsertTemplateAction](InsertTemplateAction)
A quick context menu action on code editor to insert a template string for @maternaDev01

* [ConnectionHelper](ConnectionHelper)
Optionally accept connection info from the command line and/or on a [SocketServer](https://docs.oracle.com/javase/tutorial/networking/sockets/clientServer.html)

* [ConnectionHelperClient](ConnectionHelperClient)
A simple command line client for the ConnectionHelper socket server.

* [WorksheetAction](WorksheetAction)
How to add actions to the worksheet context menu and / or toolbar; execute the action directly or in a background task; and present advanced / detailed information in a result panel.
