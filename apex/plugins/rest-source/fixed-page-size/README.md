This example plug-in demonstrates how to implement pagination support for a REST API which uses a fixed page size
and URL parameter for the page number. The plug-in uses "api.themoviedb.org" as example REST API.

### PREREQUISITES

To use the "themoviedb.org" REST API, you need an API key. Register for an account on themoviedb.org in order to get 
the API key. 

### USAGE

* Create an application
* Import the Plug-In in Shared Components - Plug-Ins
* Create a new REST Data Source in Shared Components - REST Data Sources
* Make sure to use the new Plug-In type as the REST Data Source Type
* On the Authentication screen, pick "URL Query String" as the credential type, use **api_key** as name and your
  themoviedb.org API Key as the value
* Click **Discover** and when you see sample data, click **Create** to create the REST Data Source
* Create a new page in your application and add an **Interactive Report** with the new REST Data Source as
  its data source.
* Run the page. The report should show no contents. Type in a search in order to see data from the "themoviedb.org" 
  REST API in your APEX application.

Note that the Plug-In does not execute a REST request if no search term (module parameter **query**) is passed in.

### DISCLAIMER

*  These scripts are provided for educational purposes only.
*  They are NOT supported by Oracle World Wide Technical Support.
*  The scripts have been tested and they appear to work as intended.
*  You should always run scripts on a test instance.
