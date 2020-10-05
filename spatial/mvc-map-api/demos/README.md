Oracle Maps API is a client-side JavaScript library. It is often used together with Oracle Map Visualization (Viz) Server, but it can also be used for application development without Map Viz server.

These demos demonstrate Oracle Maps API functionality. Oracle Maps API is not included in this repository, but it can be downloaded(see Oracle Resources section below).

1) Prerequisite:
You need to have a basic understanding about web applications, Java EE web containers, HTML, and JavaScript. It is also helpful to have some basic knowledge about the spatial features in Oracle Database. Map Viz server is certified for Oracle WebLogic Server, but it can also be deployed to Apache Tomcat Java EE container. It is assumed that you are familiar with the basic steps of deploying a web application to a web container.

2) Preparation:
Software preparation: If Map Viz server is required, then you need to install Oracle Database and download and deploy Map Viz server to a web container (see Oracle Resources section below for details).

Data preparation: Some demos require Map Viz server. The data source connection defined in Map Viz server connects to an Oracle Database server. The schema is created using the dataset downloaded from Oracle Resources (see Oracle Resources section below for details).

3) Deploy the demos:
This collection of demos is not in an EAR or WAR file. You need to manually copy the demos/ folder into your web content folder before you access the demos. 

4) Structure of the demo files:
For each individual demo, the related files and dataset can be found in the following folders:

The index.html file at the root loads the demos/h/tilelayer.html. This demos/h/tilelayer.html file and other html files in this demos/h folder load the actual demos HTML files stored in demos/u/ folder.

In folder demos/u/, each html file is a demo.

The JavaScript files for each demo are stored in demos/u/js/ folder.

Some demos require local datasets that are stored in folder demos/u/data.
  
5) Geometry Editing demo:
This demo shows editing features in Oracle Maps API for creating/editing geometry features. Not all features of the UI are implemented yet. This demo requires you to create three tables for points, line strings, and polygons. 

The SQL script for creating them is included at the beginning of the demos/u/js/geom_edit.js file, in the comment section. Three pre-defined geometry themes and some styles are also required. They are created using Oracle Map Builder and they are often called Map Viz metadata. Map Builder is a standalone Java application.  The metadata is exported using Map Builder and the data file is found as geometry_edit.dat at the root. You use Map Builder to import the data file into your database schema if you want to run the Geometry Editing demo.

6) Oracle Resources:
You download the Map Visualization Component from https://www.oracle.com/database/technologies/spatial-studio/spatial-graph-map-vis-downloads.html. It contains the Map Visualization Server and the Oracle Maps API.

You download the sample dataset from https://www.oracle.com/middleware/technologies/mapviewer-archive-downloads.html. On this page, search for "Download MVDEMO Sample Data Set (ZIP - 414MB)".

If you have questions, post them to https://community.oracle.com/community/groundbreakers/database/oracle-database-options/spatial.

