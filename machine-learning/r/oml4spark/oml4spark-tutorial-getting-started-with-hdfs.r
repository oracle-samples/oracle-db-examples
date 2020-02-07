########################################################
# OML4Spark Tutorial 001 - Getting Started with HDFS   #
#                                                      #
# Simple OML4Spark 2.8.x Introduction                  #
#                                                      #
# Accessing Data in HDFS, pushing data from R to HDFS  #
# and vice-versa                                       #
#                                                      #
# (c) 2020 Oracle Corporation                          #
#                                                      #
########################################################

# Once inside the R Session, either on a Terminal running R
# or inside an RStudio Server session, the following command loads
# the OML4Spark library and all its necessary components
library(ORCH)

# The first time the libraries load it should take some time testing the
# appropriate HDFS, HIVE and other environment conditions. The initializations
# after that should be faster.

# If there are problems with the configuration:
# On a BDA or BDCS, make sure the file /usr/lib64/R/etc/RBDAprofiles/Renviron.site 
# is the correct one for your CDH and Spark releases.
# On BDC and on DIY Cloudera or Hortonworks clusters, the file needs to be
# one level up: /usr/lib64/R/etc/Renviron.site

# The OML4Spark Installation Guide contains sample Renviron.site files for
# different configurations
# https://www.oracle.com/technetwork/database/database-technologies/bdc/r-advanalytics-for-hadoop/documentation/index.html

# Also make sure the user that is running the commands has an available
# home folder in HDFS: /user/my-user-name

# When using RStudio Server on a BDA or BDCS, you might need to copy
# that file to one level up as well, to /usr/lib64/R/etc, plus
# add the following line to /etc/rstudio/rserver.conf
# rsession-ld-library-path=/usr/java/latest/jre/lib/amd64/server:/usr/lib64/R/lib:/opt/cloudera/parcels/CDH/lib/hadoop/lib/native:/usr/lib64/R/port/Linux-X64/lib

### SIMPLE R DATAFRAME PUSH TO HDFS ###

# We can list the available files under the current user HDFS folder
hdfs.ls()

# We can also list other folders that the user has authorization
# to look at
hdfs.ls('/user')

# We can push one of the basic datasets included with R, called iris, to HDFS,
# and map it with an OML4Spark dfs.id object
iris.hdfs <- hdfs.put(iris)

# The resulting local object is just a string that points to the temporary location
# where the HDFS file was pushed to.
# This pointer is going to exist in the local memory of R
ls()

# And we can check that the actual contents of the object is just a set of
# strings
iris.hdfs

# This structure can now be used for working with OML4Spark algorithms and commands

# Physically it contains a CSV file in HDFS (normally named part-00000) and a 
# special OML4Spark Metadata Object (called __ORCHMETA__) that keeps track of the
# information on the file.
# Let's list the contents of the folder where the dfs.id is pointing to:
hdfs.ls(iris.hdfs[1])

# We can view the complete description of the file by using the following command:
hdfs.describe(iris.hdfs)

# We can also see the contents of a few rows on the file with
# the following command
hdfs.head(iris.hdfs)

# You will notice that the visualization is not as nice as R's native, because we
# are only reproducing whatever is in HDFS

# A simple function can be used to reproduce a nicer print of the head of the
# dfs.id object
hdfs.head.r <- function(dfs.id,n=6) {
                  res <- read.csv(text=hdfs.head(dfs.id,n),header=FALSE)
                  names(res) <- unlist(strsplit(hdfs.describe(dfs.id)[5,2],','))
                  return(res)
                }

# Let's try the new function on our dfs.id
# The default number of rows is 6, but we can request more with the parameter "n"
hdfs.head.r(iris.hdfs,n=10)

# Another valuable information when dealing with large datasets is the
# Column Data Types and Column Names
# We can create the following simple function to extract that from a dfs.id
hdfs.types <- function(dfs.id) {
                var.types <- strsplit(as.character(hdfs.describe(dfs.id)[4,]),',')[[2]]
                var.names <- strsplit(as.character(hdfs.describe(dfs.id)[5,]),',')[[2]]
                return(data.frame(Variable_Name=var.names,Variable_Type=var.types))
              }
  
# Let's review our dfs.id column names and types
hdfs.types(iris.hdfs)


### PERMANENT STORAGE IN HDFS ###

# Another concept is he one of the permanent location for the dfs.id
# Instead of pushing it to a temporary location, we can push data
# to a permanent location in HDFS, and overwrite it if it already exists.
# by default, without a subfolder, the dfs.name will write data to the
# current user's home folder
iris.hdfs.permanent <- hdfs.put(iris, dfs.name = 'iris_data_test', overwrite = TRUE)

# The new permanent location is by default under the current user's home in HDFS
iris.hdfs.permanent

# Let's get the HDFS location into an R character object so we can locate it later
hdfs.location <- iris.hdfs.permanent[1]
print(paste0('The permanent location of the file is ',hdfs.location))

# Now that our working file is stored in HDFS permanently, we can come back
# another day to continue working on our Analysis.
# We can now use the "hdfs.attach()" function against the permanent dataset location
# to create a dfs.id link to the CSV file, and use it in our session. 

# Let's first remove the original pointer to the permanent location.
rm(iris.hdfs.permanent)

# We now attach the dataset in the permanent location (folder) that we know the file is at
# Remember that this location is a physical HDFS folder containing both the actual CSV data 
# (usually named named part-00000, part-00001, and so on depending on how many partitions it needs)
# and the OML4Spark Metadata in a file named __ORCHMETA__ .
iris.hdfs.permanent <- hdfs.attach(hdfs.location)

# If you don't remember the location, you can always do an "hdfs.ls" on the folder
# usually used for storing data.  In our example, if the previous commands were executed, 
# there must be a folder called "iris_data_test".  We could attach it using just that folder
# name or the entire path to it ("/user/your-user/iris_data_test") as well
hdfs.ls()

# Just as before, we can use our function to see the first 10 records on the dfs.id
hdfs.head.r(iris.hdfs.permanent,n=10)

# We can also examine the size of the Dataset by running the hdfs.dim() command.  
# Usually if the source of data was originally an R Dataframe, the number of rows and columns
# is automatically pushed to the OML4Spark Metadata when we first did the hdfs.put().

# On the other hand, if it is the first time OML4Spark is seeing a CSV folder in HDFS, the 
# hdfs.attach() function is going to verify all columns and column types, but is not necessarily 
# going to check the number of rows.

# Then, the first time we run an hdfs.dim() function, it might quickly count the records (if it's
# a small dataset), ask to run a Map Reduce job (if it's a larger dataset) or try to use a
# Spark Session for counting if you have created one with spark.connect() 
# (more details on Spark and OML4Spark in the next Tutorial)

# Once hdfs.dim() is executed successfully, the number of rows is permanently stored in the OML4Spark
# Medatada for quick retrieval on any subsequent request.
hdfs.dim(iris.hdfs.permanent)

# Or for a nicer print of the sizes
size <- formatC(hdfs.dim(iris.hdfs.permanent),format='fg',big.mark = ",") 
paste0('Dataset Size is: ',size[1],' rows and ',size[2],' columns')

### PULLING HDFS DATA TO R LOCAL MEMORY ###

# Now that we learned how to create a local pointer to the data that is
# stored in HDFS, we can use functions to pull the data locally into memory

# Of course one should be careful with dataset sizes when doing this. 
# Pulling millions of records into the local R memory is not recommended, since
# it can cause processing problems in the Edge Node in your Big Data Cluster,
# and can affect other users and other processes running in the same server as
# well

# We will use the function hdfs.get() with the dfs.id that we have 
iris.local <- hdfs.get(iris.hdfs.permanent)

# We can check the class of the resulting object from the hdfs.get(), which
# should be a "data.frame"
class(iris.local)

# Comparing this file we imported from HDFS with the original iris dataset
# that comes with R should be identical
identical(iris.local, iris)

# END OF: OML4Spark Tutorial 001 - Getting Started with HDFS



