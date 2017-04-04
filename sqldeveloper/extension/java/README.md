# SQL Developer Examples
## Standard Extensions (java)
Standard extensions are jar files with an [OSGi](https://en.wikipedia.org/wiki/OSGi) manifest and an extension.xml defining the extension and how it integrates with SQL Developer.

If you are not using *D:/sqldeveloper-4.2.0.16.356.1154-x64/sqldeveloper* as your development copy, change sqldev.dir in extension/build.properties and any *.userlibraries in the java projects before building.
 
* DependencyExample  
This example is built with ant but is also set up for editing & (remote) debugging in the eclipse extension project. Building this example requires two external libraries listed below. Copy the required jar files to DependencyExample/lib. The exact jars needed as well as a definition for eclipse of which SQLDeveloper jars can be found in *DependencyExample/DependencyExample.userlibraries* which you will also need to import to use eclipse.
    * [FXDiagram 0.35.0](http://dl.bintray.com/jankoehnlein/FXDiagram/standalone/:fxdiagram-jars-0.35.0.zip "fxdiagram-jars-0.35.0.zip")  
    * [KIELER KLay Layouters 0.14.0](http://rtsys.informatik.uni-kiel.de/~kieler/files/release_pragmatics_2015-02/klay/klay_2015-02.jar "klay_2015-02.jar")

