# SQL Developer Examples
## Standard Extensions (java)
Standard extensions are jar files with an [OSGi](https://en.wikipedia.org/wiki/OSGi) manifest and an extension.xml defining the extension and how it integrates with SQL Developer.

[Set up your environment](../../setup.md). If using the eclipse project, also modify paths in *SQLDeveloper4.2.userlibraries* and import into eclipse.

* [packaged XML](../xml/packaged)  
XML Examples packaged as an extension.jar  

* [DependencyExample](DependencyExample) 
An example editor and viewer for object dependency graphs.

* [DumpObjectTypesAction](DumpObjectTypesAction)
A quick object action to dump the list of connection / objects types as INFO message in the log window. Plus one to show the selected object's connection / object type.

* [ContextMenuAction](ContextMenuAction)
A quick context menu action on FUNCTION, PROCEDURE code editor to insert a static string and
a PLDoc template if PL/Scope information is available.
