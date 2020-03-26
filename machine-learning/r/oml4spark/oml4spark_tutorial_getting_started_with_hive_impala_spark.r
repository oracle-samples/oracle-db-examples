#######################################################
# OML4Spark Tutorial 002 - Getting Started with HIVE,      
#   IMPALA and Spark Data Frames                                                
# 
# oml4spark_tutorial_getting_started_with_hive_impala_spark.r
# 
# Accessing Data stored as HIVE tables, using the 
# Transparency Layer to process data via HIVE and IMPALA, 
# executing queries, loading data into and from HDFS, 
# loading data into and from R data frames, executing 
# HQL queries, loading data into Spark DataFrames, load data
# from HIVE and manipulate the Spark DataFrames via Spark SQL.
#
# - Load the OML4Spark libraries and connect to HIVE
# - Pushing R dataframe to HIVE
# - Statistics and Aggregation functions
# - Subsetting Hive Tables
# - Connect to IMPALA
# - Pushing R dataframe to IMPALA
# - Statistics and Aggregation functions
# - Subsetting IMPALA Tables
# - Manipulating Hive Tables (via Spark SQL) and Spark DF
# - Creating a Spark Session for OML4Spark and query Hive metadata
# - Loading the Hive table into Spark DF
# - Statistics and Aggregation functions
# - Subsetting Spark DataFrames
# - Joining Spark DataFrames
#                                                      
# Copyright (c) 2020 Oracle Corporation                        
# The Universal Permissive License (UPL), Version 1.0          
#                                                              
# https://oss.oracle.com/licenses/upl/   
#                                                      
#######################################################

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
# the Renviron.site file to one level up as well, to /usr/lib64/R/etc

# On any environment, when using RStudio Server add the following line to /etc/rstudio/rserver.conf
# (if you are not using Cloudera, you need to find the proper folder for your ../hadoop/lib/native)
# rsession-ld-library-path=/usr/java/latest/jre/lib/amd64/server:/usr/lib64/R/lib:/opt/cloudera/parcels/CDH/lib/hadoop/lib/native:/usr/lib64/R/port/Linux-X64/lib

# OML4Spark's HIVE connectivity will use the HIVE Server2 Thrift Port, usually 10000 (hive.server2.thrift.port setting in Cloudera Manager).

# Connect to HIVE using the default port. Password is not necessary since the OS user would have been authorized access to
# HDFS and HIVE
ore.connect(type='HIVE',host='cfclbv3873',user='oracle', port='10000', all=TRUE )

# In case of a Keberized Cluster, additional settings are needed:
# ore.connect(type='HIVE',
#             host='bdax72bur09node01',
#             ssl='true', 
#             sslTrustStore='/opt/cloudera/security/jks/testbdcs.truststore', 
#             principal='hive/cfclbv3873@BDACLOUDSERVICE.ORACLE.COM',
#             all=TRUE )

# Optionally we can ignore the difference between orders in HIVE and local R
options("ore.warn.order" = FALSE)

# List current Tables available for the connection
ore.ls()

# We will create a random dataset and push it to HIVE for the next operations

# Creating a random R Data Frame with 25 columns and 100 k rows
nCols <- 25
nRows <- 100000
simulated_data <- data.frame(cbind(id=(1:nRows),matrix(runif(nCols*nRows), ncol=nCols)))

# Verify the size of the local dataframe
dim(simulated_data)

# Pushing the simulated data to HDFS, keeping a local reference to it
# (some 6s depending on Cluster power) 
hdfs_simul_data <- hdfs.put(simulated_data, dfs.name = 'simul_data', overwrite = TRUE)

# Load the HDFS data into a HIVE Table
# First we delete the table if it already exists
if (ore.exists('simul_table')) ore.drop(table='simul_table')

# Then we point HIVE to the HDFS data and register it as a table
hdfs.toHive(hdfs_simul_data, table = "simul_table")

# When we list the current Tables available, we should now see the "simul_table"
ore.ls()

# Let's check the contents of the Table in HIVE
# (some 28s depending on Cluster power) 
head(simul_table)

# Now create a new temporary view, based on the current simul_table
temp_table <- simul_table

# We are going to alter the temporary view via "Transparency Layer"
# Transparency layer functions include creating new variables, 
# and generating Aggregation Statistics
# Create a new column named "new_hive_var1" based on columns v2 and v3
# and a new column named "new_hive_var2" based on columns v5 and v6
temp_table$new_hive_var1 <- 1*(((temp_table$v2 + temp_table$v3)/2)>0.5)
temp_table$new_hive_var2 <- 1*(((temp_table$v5 + temp_table$v6)/2)>0.5)

# Check that the new column exists at the end of the temporary view
# (some 28s depending on Cluster power) 
names(temp_table)

# Time to count the number of Rows in the table via HIVE
# (some 28s depending on Cluster power) 
system.time({siz <- nrow(temp_table);print(formatC( siz,format = "fg",big.mark = ",")) })

# Create a new physical Table from our manipulated view
# (some 17s depending on Cluster power) 
if (ore.exists('simul_table_extra')) ore.drop(table='simul_table_extra')
ore.create(temp_table, table='simul_table_extra')

# Specialized OML4Spark Summary function for HIVE
# (some 1m30s depending on Cluster power) 
options(width=160)
orch.summary(simul_table_extra, var = c("v2", "v3", "v4", "v5"),
             class = c("new_hive_var1"),
             stats = c("min","mean", "stddev","max"), order = c("type", "class"))

# Show the help for the orch.summary
?orch.summary

# Using the Transparency Layer function "aggregate"
# (less than 60s depending on Cluster power) 
agg <- aggregate( simul_table_extra$v3,
                  by = list(simul_table_extra$new_hive_var1),
                  FUN = mean)
names(agg) <- c("Attribute 1","Average for column v3")
print(agg)

# Adding a Factor attribute to the aggregation
# (less than 60s depending on Cluster power) 
agg <- aggregate( simul_table_extra$v3,
                  by = list(simul_table_extra$new_hive_var1,
                            simul_table_extra$new_hive_var2),
                  FUN = mean)
names(agg) <- c("Attribute 1","Attribute 2","Average for column v3")
print(agg)

# Using the Transparency Layer function "table"
# for Cross-tabulation of two factor columns
# (less than 60s depending on Cluster power) 
tab <- table('Variable 1'=simul_table_extra$new_hive_var1,
             'Variable 2'=simul_table_extra$new_hive_var2)
print(tab)

# Using the Transparency Layer function "colMeans" for example
# to check the Average values of all columns at once
# (less than 60s depending on Cluster power) 
colMeans(simul_table_extra)


# Using a subset of the data
# We can create a new view that is a filter on the original using subset
new_temp_table <- subset(simul_table_extra, 
                         new_hive_var1==1, 
                         select = c("v2", "v3", "v4", "v5", 
                                    "new_hive_var1","new_hive_var2"))

# Visualize the new Data 
# (some 28s depending on Cluster power) 
head(new_temp_table)                                    

# Bring the subset of data from HIVE to local memory for additional processing
# (some 13s depending on Cluster power) 
local_subset_of_data <- ore.pull(new_temp_table)

# Summary statistics from the local data for example
summary(local_subset_of_data)


#################################
#  Working with Cloudera IMPALA #
#################################

# OML4Spark's IMPALA connectivity will use IMPALA's Daemon HiveServer2 Port, usually 21050 (hs2_port setting in Cloudera Manager)
# The ore.connect() command will automatically disconnect any previous connections
# With the all=FALSE option, we are asking not to sync all the tables with the environment, and we will have
# to specify the tables we want to work with manually using an ore.sync, or upload new tables
ore.connect(type='IMPALA',host='cfclbv3872',port='21050',user='oracle', all=FALSE)

# In the case of a Kerberized Cluster  
# ore.connect(type='IMPALA', 
#             port='21050', 
#             AuthMech='1', 
#             KrbRealm='BDACLOUDSERVICE.ORACLE.COM', 
#             KrbHostFQDN='cfclbv3872', 
#             KrbServiceName='impala', 
#             all=TRUE)

# Optionally we can ignore the difference between orders in IMPALA and local R
options("ore.warn.order" = FALSE)

# We can resync and reuse the original table created in the HIVE Session above
ore.sync(table='simul_table')
ore.attach()
ore.ls()

# We can also create a new table and overwrite the old one
# Let's drop the old table
ore.drop(table='simul_table')

# Creating a random R Data Frame with 25 columns and 100 k rows
nCols <- 25
nRows <- 100000
simulated_data <- data.frame(cbind(id=(1:nRows),
                                   matrix(runif(nCols*nRows), 
                                          ncol=nCols)))

# Verify the size of the local dataframe
dim(simulated_data)

# Load the simulated into IMPALA
# (some 28s depending on Cluster power) 
ore.create(simulated_data, table='simul_table', overwrite = TRUE)

# Now create a new temporary view, based on the current simul_table
temp_table <- simul_table

# We are going to alter the temporary view via "Transparency Layer"
# Transparency layer functions include creating new variables, 
# and generating Aggregation Statistics
# Create 2 new columns named "new_impala_var1" and "new_impala_var2"
# based on columns v2 and v3
temp_table$new_impala_var1 <- 1*(((temp_table$v2 + temp_table$v3)/2)>0.5)
temp_table$new_impala_var2 <- 1*(((temp_table$v5 + temp_table$v6)/2)>0.5)

# Check that the new columns exists at the end of the temporary view
# (some 1s depending on Cluster power) 
head(temp_table)

# Time to count the number of Rows in the table via IMPALA
# (less than 1s depending on Cluster power) 
system.time({siz <- nrow(temp_table);
print(paste0('Total Records: ',
             formatC(siz,
                     format = "fg",
                     big.mark = ","))) })

# Using the Transparency Layer function "aggregate"
# (less than 2s depending on Cluster power) 
agg <- aggregate( temp_table$v3,
                  by = list(temp_table$new_impala_var1),
                  FUN = mean)
names(agg) <- c("Attribute 1","Average for column v3")
print(agg)

# Adding a Factor attribute to the aggregation
# (less than 2s depending on Cluster power) 
agg <- aggregate( temp_table$v3,
                  by = list(temp_table$new_impala_var1,
                            temp_table$new_impala_var2),
                  FUN = mean)
names(agg) <- c("Attribute 1","Attribute 2","Average for column v3")
print(agg)

# Using the Transparency Layer function "table"
# for Cross-tabulation of two factor columns
# (less than 2s depending on Cluster power) 
tab <- table('Variable 1'=temp_table$new_impala_var1,
             'Variable 2'=temp_table$new_impala_var2)
print(tab)

# Using the Transparency Layer function "colMeans" for example
# to check the Average values of all columns at once
# (less than 2s depending on Cluster power) 
colMeans(temp_table)

# Using a subset of the data
# We can create a new view that is a filter on the original using subset
new_temp_table <- subset(temp_table, 
                         new_impala_var1==1, 
                         select = c("v2", "v3", "v4", "v5", 
                                    "new_impala_var1", "new_impala_var2"))

# Check new limited dataset
# (less than 1s depending on Cluster power) 
head(new_temp_table)    

# Bring the subset of data from IMPALA to local memory for 
# additional processing
# (less than 2s depending on Cluster power) 
local_subset_of_data <- ore.pull(new_temp_table)

# Run a local histogram of the producrt of 2 of the random variables
hist(local_subset_of_data$v5*local_subset_of_data$v4,
     col='red',breaks=50)


##################################
#  Working with Spark Data Frames
#  and Spark SQL
##################################

# Create a Spark Session, disconnecting any previous one if exists
# remember to add the option enableHive= TRUE to have access to the
# HIVE Metadata from Spark. This option is not needed if you are 
# already connected to HIVE via ore.connect(...)
# The defaults are:
#    spark.executor.cores='2'
#    spark.executor.instances='2'
# These can be changed or ignored for Dynamically Allocated clusters 
if (spark.connected()) spark.disconnect()

spark.connect(master='yarn',memory='4g', enableHive = TRUE)

# Check available Databases in HIVE from Spark with Spark SQL
queryResult <- orch.df.sql('show databases')

# Collect the results locally
orch.df.collect(queryResult)

# Execute a Show Tables, and list the database and tableName
queryResult <- orch.df.sql('show tables')
orch.df.collect(queryResult$selectExpr(c("database","tableName") ))

# Execute a Simple Count Query on the table simul_table_extra. 
# We can use show() to print the result, or it can be collected to R
queryResult <- orch.df.sql('select count(*) from default.simul_table_extra')
orch.df.collect(queryResult)

# Execution is lazily loaded by Spark, so only when we actually request the
# orch.df.collect() function to bring the result locally, the Spark job is 
# going to run
# (the first time might take 10s, if ran again it might take less than 1s)
queryResult <- orch.df.collect(orch.df.sql('select count(*) from default.simul_table_extra'))
numRows <- formatC( unlist(queryResult), 
                    format = "fg", big.mark = ",")
print(paste0('Number of rows via Spark SQL: ',numRows))

# We can load the HIVE data into a 
# Spark DataFrame for processing 
# directly in-memory with SparkDF 
# functions and Spark SQL
simul_table_df <- 
  ORCHcore:::.ora.getHiveDF(table
                            ='simul_table_extra')

# The simul_table_df is of Class Java Reference
class(simul_table_df)

# When called directly, it will show that it is
# a Java-Object, a proxy to the Spark DataFrame
str(simul_table_df)

# And we can see the a sample of 10 rows of the Spark DataFrame by using 
simul_table_df$show(10L)

# For increased performance, we can ask Spark to persist the Spark DataFrame
# This function should be used when we expect to have enough memory to hold
# the compressed data.  If data cannot entirely fit in memory, Spark will
# automatically spill to disk when needed
orch.df.persist(simul_table_df, storageLevel = "MEMORY_ONLY", verbose = TRUE)

# There are many functions associated to this rJava object
# To count the rows, one can use the $count function for example
# (because the data is pinned to memory, it should run in less than 1s)
num_rows <- formatC( simul_table_df$count() ,format = "fg",big.mark = ",")
print(paste0("Number of Rows: ",num_rows))

# We will extract all numerical columns from the Spark DataFrame, using
# the built-in function $numericColumns
# We are capturing the output from that function and then transforming
# the output for a final string vector called "allNumericalVars"
tmp_nums <- capture.output(simul_table_df$numericColumns())
tmp_extr <- gsub(".*\\(\\s*|\\).*", "", tmp_nums)
tmp_split <- strsplit(tmp_extr,',')
allNumericalVars <- unlist(lapply(tmp_split, 
                                  function(x) trimws(gsub( "#.*$", "", x ))))

# Review the final string vector
allNumericalVars

# Let's remove the "id" column from the list since correlations
# with the ID do not make sense
allNumericalVars <- allNumericalVars[!allNumericalVars %in% "id"]

# We then invoke the statistics interface ($stat) on the Spark DataFrame
simul_stats <- simul_table_df$stat()

# For each Numerical column, the Correlation will be computed against column "v2"
# using R's sapply to repeat the function $corr
# (it should take less than 3s depending on Cluster performance)
allNumCorr <- sapply(allNumericalVars, 
                     function(x) simul_stats$corr("v2",x),
                     simplify = TRUE)

# Sort the Correlations in descending order by the absolute value
sortedAbsCorr <- allNumCorr[sort(abs(allNumCorr),
                                 decreasing = TRUE, 
                                 index.return = TRUE)$ix]

# List the resulting correlations
# We expect very small numbers since these are numbers randomly generated
options(width=160)
print(formatC( sortedAbsCorr ,format = "fg", digits = 6))

# Simple Cross-Tabulation between the two binary columns

# We can reuse the same "simul_stats" already built using the $stat function, 
# and call the $crosstab function on it
xtab_simul_local <- orch.df.collect(simul_stats$crosstab("new_hive_var1",
                                                         "new_hive_var2"))
names(xtab_simul_local)[1] <- 'NewHiveVar1 \\ NewHiveVar2 '
xtab_simul_local

# Create a Subset of the original Spark DataFrame simul_table_df 
# by selecting a few columns using the function $selectExpr()
subset_table_df <- simul_table_df$selectExpr(c("id",
                                               "v2",
                                               "v3",
                                               "v4"))

# Show the resulting subset_table_df Spark DataFrame with only 4 columns
subset_table_df$printSchema()
subset_table_df$show(10L)

# Another option is to select the desired columns directly in the Spark SQL query
subset_query_df <- orch.df.sql('select id, v2, v3, v4 from default.simul_table_extra')
subset_query_df$show(10L)

# Two Spark dataFrames with the same columns can be appended with the
# union() function on one of them
combined_subsets <- subset_table_df$union(subset_query_df)

# The structure of the combined Spark DF should have same 4 attributes...
combined_subsets$printSchema()

# ... but if we verify the number of records of the combined Spark DF
# it should now be twice as large as the original
print(paste0('Number of records on the combined Spark DF: ',
             formatC( combined_subsets$count() ,
                      format = "fg",
                      big.mark = ",", 
                      digits = 8)))

# For joining Spark DataFrames, the easiest method is through Spark SQL
# Make sure the tables you want to join are available for Spark SQL
queryResult <- orch.df.sql('show tables')
orch.df.collect(queryResult$selectExpr(c("database","tableName") ))

# Note that the temporary Spark DF we created called "subset_query_df" 
# is not available yet for querying

# We need to register the subset_query_df as a temporary view for 
# the Spark SQL engine be able to see it
orch.df.createView(data = subset_query_df, viewName = "subset_query")

# Now at the bottom of the list, there should be a new view 
# with an empty database name, called subset_query
queryResult <- orch.df.sql('show tables')
orch.df.collect( queryResult$selectExpr(c("database","tableName") ))

# Now we can join the original table with the subset view
joined_table_df <- orch.df.sql('select simul_table.id, simul_table.v12 simv12, 
                                simul_table.v14 simv14, subset_query.v2 subv2, 
                                subset_query.v3 subv3, subset_query.v4 subv4
                                from default.simul_table, subset_query 
                                where simul_table.id == subset_query.id')

# Finally we can also bring the Spark DF to the local memory
# in order to perform any other R processing on it
joined_table_local <- orch.df.collect(joined_table_df)

# The data contents from the Spark DF can be seen with
joined_table_df$show(10L)

# And on the local R dataframe all normal R functions apply
hist(joined_table_local$simv12, col='red', breaks=50)





