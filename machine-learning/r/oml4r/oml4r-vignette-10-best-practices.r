################################################
##
## Oracle Machine Learning for R Vignette
##
## OML4R Best Practices
## Predicting Flight Delays - U.S. Airports
##
## (c) 2020 Oracle Corporation
##
################################################

## Data Explanation
## Flights data, from nycflights13 package: 
## An R data package containing all out-bound flights from NYC in 2013 + useful metdata
## flights: Data frame with variables:
# year,MONTH,day: Date of departure
# dep_time,arr_time: Actual departure and arrival times, local tz.
# sched_dep_time,sched_arr_time: Scheduled departure and arrival times, local tz.
# DEP_DELAY,ARR_DELAY: Departure and arrival delays, in minutes. Negative times represent early departures/arrivals.
# hour,minute: Time of scheduled departure broken into hour and minutes.
# carrier: Two letter carrier abbreviation. See airlines to get name
# tailnum: Plane tail number
# flight: Flight number
# origin,DEST:Origin and DESTination. See airports for additional metadata.
# air_time: Amount of time spent in the air, in minutes
# DISTANCE: DISTANCE between airports, in miles
# time_hour: Scheduled date and hour of the flight as a POSIXct date. Along with origin, can be used to join flights data to weather data.
#
## Source: RITA, Bureau of transportation statistics, http://www.transtats.bts.gov/DL_SelectFields.asp?Table_ID=236 

## Transparency layer - exploratory analysis

# Load the ORE library

library(ORE)

# Turn off row ordering warnings

options(ore.warn.order=FALSE)

# Create an ORE Connection

ore.connect(user        ="rquser",
            conn_string ="OAA1",
            host        ="localhost",
            password    ="rquser",
            all         = TRUE)

rm(list = ls())  # housekeeping

# Load flight data

library(nycflights13)
ore.create(flights, "FLIGHTS")


# list tables in the database schema 

ore.ls()

# Return data class, column names and dimensions for table FLIGHTS

class(FLIGHTS)
names(FLIGHTS)
dim(FLIGHTS)

# Recode MONTH variable

FLIGHTS$MONTH2 <- as.ore.factor(FLIGHTS$month)

FLIGHTS$MONTH2 <- ore.recode(FLIGHTS$MONTH2,                     
                       old=c("1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12"), 
                       new=c("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sept", "Oct", "Nov", "Dec"))

# Pull data from a database table to a local R data.frame

flights <- ore.pull(FLIGHTS)
class(flights)
head(flights)

str(flights)     # data.frame

str(FLIGHTS)     # ore.frame proxy object

FLIGHTS@dataQry  # underlying data query for proxy object

head(FLIGHTS)

# Column selection using standard R syntax

names(FLIGHTS)

dat <- FLIGHTS[, c("year","dest","arr_delay")]
dim(dat)

# Column Indexing

head(dat)
head(FLIGHTS[, c(1,5,17)])
head(FLIGHTS[, -(3:19)])

# Row filtering

dat1 <- dat[dat$arr_delay > 20, ]
head(dat1, 3)

dat2 <- dat[dat$arr_delay > 20, c(1,3)]
head(dat2, 3)

dat3 <- dat[dat$arr_delay > 20 | dat$dest=="SEA", 1:3]
head(dat3, 6)


# Aggregation

agg1 <- aggregate(FLIGHTS$dest, 
                     by = list(FLIGHTS$dest), 
                     FUN = length)

names(agg1) <- c("Destination","FlightCount")
class(agg1)
head(agg1)

agg2 <- aggregate(FLIGHTS$arr_delay, 
                     by = list(FLIGHTS$dest, FLIGHTS$carrier), 
                     FUN = sd, na.rm=TRUE)

names(agg2) <- c("Destination", "Airline", "sd(ArrivalDelay)")
head(agg2, 10)

# Occurrences showing a delay

library(OREdplyr)
HAVEDELAY <-filter(FLIGHTS, arr_delay>0) 
class(HAVEDELAY)

head(HAVEDELAY, 3)

NDELAYS <-count(HAVEDELAY, MONTH2) # count delays for each MONTH
names(NDELAYS) <- c("MONTH", "DELAYS")
NDELAYS

ore.sort(NDELAYS, by=c("DELAYS", "MONTH")) # sort delays for each MONTH


## Machine Learning Algorithms - model evaluation and results

# ore.lm: build linear model using ORE's parallel distributed version of lm()

mod.orelm <- ore.lm(arr_delay ~ dep_time + month, FLIGHTS)
summary(mod.orelm)  # view model coefficients and summary statistics
coef(mod.orelm)

# Score data to flight delays

pred.orelm <- predict(mod.orelm, newdata=FLIGHTS)
summary(pred.orelm)
head(cbind(FLIGHTS, pred.orelm))

# Build a Support Vector Machine regression model using ore.odmSVM

mod.svm <- ore.odmSVM(arr_delay ~ dep_time + month, FLIGHTS, type="regression")
summary(mod.svm)
coef(mod.svm)
pred.svm <- predict(mod.svm, FLIGHTS, "month")
head(pred.svm)


## Embedded R Execution

# Building linear model on database server

mod.lm <- ore.tableApply(FLIGHTS[FLIGHTS$MONTH2=="Jan",],
                      function(dat) {
                        mod <- lm(arr_delay ~ dep_time, dat)
                        mod
                      });

mod.local <- ore.pull(mod.lm)
class(mod.local)
summary(mod.local)

# Group Apply

FLIGHTS_Q1 <- FLIGHTS[FLIGHTS$MONTH2 %in% c("Jan", "Feb", "Mar"),]
modlm.list1 <- ore.groupApply(FLIGHTS_Q1, FLIGHTS_Q1$MONTH2,
                          function(dat) {
                            lm(arr_delay ~ dep_delay + distance, dat)
                          })

summary(modlm.list1$Jan) ## return model for MONTH of January

# Store script in R Script Repository and invoke by name

ore.scriptDrop("arrdelay_lm")
ore.scriptCreate("arrdelay_lm",
                 function(dat) {
                   lm(arr_delay ~ dep_delay + distance, dat)
                 })

modlm.list2 <- ore.groupApply(FLIGHTS, FLIGHTS$MONTH2, 
                           FUN.NAME="arrdelay_lm")

modlm.list2 <- ore.pull(modlm.list2)
summary(modlm.list2$Jan) ## return model for MONTH of January


## ORE datastore

ore.delete(name="myModels") # housekeeping

# Save objects to datastore

ore.save(mod.svm, mod.orelm, modlm.list1, modlm.list2, name="myModels", description="My Saved Models") 
ore.datastoreSummary(name="myModels") # summary of specific datastore
ore.datastore() # show datastores

rm(mod.svm, mod.orelm, modlm.list1, modlm.list2)
ls()

# Load datastore

ore.load(name="myModels")

mod.svm

## External Procedures Resource Monitoring (extproc processes)

ore.doEval(function() {Sys.getpid()})   # get extproc PID; serial function execution

# Default DB parallelism:
# For a single instance, DOP = PARALLEL_THREADS_PER_CPU x CPU_COUNT
# This VM: Default DOP = 2 x 4 = 8

# For Exadata/RAC configuration, DOP = PARALLEL_THREADS_PER_CPU x CPU_COUNT x NUMBER_OF_NODES_IN_CLUSTER

# Default DB operation: only parallelize when necessary; parallelism requires overhead and may not
# yield performance benefits for queries on small to medium-sized tables

# The DOP is determined in the following priority order: 
# parallel argument in embedded R functions, session, table

# In Linux terminal window, execute "top | grep extproc"
# to view R processes running as external procedures and their associated Linux PIDs


# Table parallelism

# Tables are not enabled to run in parallel by default (DOP 1 = serial execution)

ore.exec("alter table FLIGHTS noparallel") 

# or, equivalently,

ore.exec("alter table FLIGHTS parallel 1") 
options(ore.parallel=NULL) 

# MONTH2 contains 12 partitions

unique(FLIGHTS$MONTH2)

ore.sync(query=c("FLIGHTS_DOP"="SELECT degree FROM user_tables WHERE table_name = 'FLIGHTS'"))
FLIGHTS_DOP


test1a <- ore.groupApply(FLIGHTS,
                         FLIGHTS$MONTH2,
                         function(dat) {
                         paste("pid", Sys.getpid(), sep="-")
                         })

test1a.loc <- ore.pull(test1a)

# extproc PIDs that service each group, or partition

unlist(test1a.loc)

# 1 unique extproc PID 

unique(unlist(test1a.loc))

# Assign FLIGHTS table DOP 3

ore.exec("alter table FLIGHTS parallel 3")

ore.sync(query=c("FLIGHTS_DOP"="SELECT degree FROM user_tables WHERE table_name = 'FLIGHTS'"))
FLIGHTS_DOP

test1b <- ore.groupApply(FLIGHTS,
                         FLIGHTS$MONTH2,
                         function(dat) {
                           paste("pid", Sys.getpid(), sep="-")
                         })

test1b.loc <- ore.pull(test1b)

# extproc PIDs that service each group, or partition

unlist(test1b.loc)

# 3 unique extproc PIDs 

unique(unlist(test1b.loc))

ore.exec("alter table FLIGHTS parallel 1")   #housekeeping


# Setting parallelism within embedded R function

# assign DOP 4 to the embedded R function execution

test2 <- ore.groupApply(FLIGHTS,
               FLIGHTS$MONTH2,
               function(dat) {
               paste("pid", Sys.getpid(), sep="-")
               }, parallel=4)

test2.loc <- ore.pull(test2)

# extproc PIDs that service each group, or partition

unlist(test2.loc)

# 4 unique extproc PIDs 

unique(unlist(test2.loc))


# Setting session-level parallelism

# set parallel to DOP 4

options(ore.parallel=4)

test3 <- ore.groupApply(FLIGHTS,
                         FLIGHTS$MONTH2,
                         function(dat) {
                           Sys.getpid()
                         })

test3.loc <- ore.pull(test3)

# extproc PIDs that service each group, or partition

unlist(test3.loc)

# 4 unique extproc PIDs

unique(unlist(test3.loc))

# Show parallel setting precedence (parallel argument -> session-> table)

# parallel argument takes precedence over session parallelism

options(ore.parallel=2)

test4 <- ore.groupApply(FLIGHTS,
                         FLIGHTS$MONTH2,
                         function(dat) {
                           paste("pid", Sys.getpid(), sep="-")
                         }, parallel=4)

test4.loc <- ore.pull(test4)

# extproc PIDs that service each group, or partition

unlist(test4.loc)

# 4 unique extproc PIDs 

unique(unlist(test4.loc))

# session parallelism takes precedence over table parallelism

options(ore.parallel=2)
ore.exec("alter table FLIGHTS parallel 4")

ore.sync(query=c("FLIGHTS_DOP"="SELECT degree FROM user_tables WHERE table_name = 'FLIGHTS'"))
FLIGHTS_DOP

test5 <- ore.groupApply(FLIGHTS,
                         FLIGHTS$MONTH2,
                         function(dat) {
                           paste("pid", Sys.getpid(), sep="-")
                         })


test5.loc <- ore.pull(test5)

# extproc PIDs that service each group, or partition

unlist(test5.loc)

# 2 unique extproc PIDs 

unique(unlist(test5.loc))

# housekeeping

ore.delete(name = "myModels")
ore.drop(table = "FLIGHTS")
ore.rm("FLIGHTS_DOP")
rm(list = ls())  
options(ore.parallel=NULL)
ore.disconnect()

# Go to SQL Developer and open script /home/oracle/ORE/oml4r-vignette-10-best-practices.sql


################################################
## End of Script
################################################
                                   



