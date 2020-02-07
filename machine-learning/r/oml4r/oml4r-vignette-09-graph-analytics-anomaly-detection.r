################################################
##
## Oracle Machine Learning for R Vignette
##
## Graph Analytics and Anomaly Detection
##
## (c) 2020 Oracle Corporation
##
################################################

# Oracle Machine Learning for R (ORE) 1.5.1 includes the 
# availability of the R package OAAgraph, which provides a single, 
# unified interface supporting the complementary use of machine learning 
# and graph analytics technologies. OAAgraph leverages the ORE 
# transparency layer and the Parallel Graph Analytics (PGX) engine from 
# the Oracle Spatial and Graph option to Oracle Database. PGX is an in-memory 
# graph analytics engine that provides fast, parallel graph analysis using 
# built-in algorithm packages, graph query / pattern-matching, and 
# custom algorithm compilation. With some thirty-five graph algorithms, 
# PGX exceeds open source tool capabilities.

# OAAgraph uses ore.frame objects representing a graph's node and edge 
# tables to construct an in-memory graph. While the basic node table includes 
# node identifiers, nodes can also have properties, stored in node table columns. 
# Similarly, relationships among nodes are described as edges - from node 
# identifier to node identifier. Each edge may also have properties stored 
# in edge table columns. Various graph algorithms can now be applied to 
# the graph, and the results such as node or edge metrics, or sub-graphs 
# can be exported again as database tables, for use by ORE machine 
# learning algorithms.

### PREREQUISITE
###  In a terminal window:
###    cd $ORACLE_HOME/md/property_graph/pgx/bin
###    $./start-server 

# Connect to ORE and PGX
library(ORE)
library(OAAgraph)
library(dplyr)
library(OREdplyr)
library(ggplot2)
options(ore.warn.order=FALSE, scipen=999)
options(java.parameters="-Xmx4G")

rm(list = ls())  # housekeeping

dbHost        <- "localhost"
dbUser        <- "rquser"
dbPassword    <- "rquser"
dbSid         <- "ORCL"
pgxBaseUrl    <- "http://localhost:7007"
dbServiceName <- 'OAA1'
dbPort        <- '1521'

ore.connect(user         = dbUser,
            service_name = dbServiceName,
            host         = dbHost,
            password     = dbPassword,
            port         = dbPort,
            all          = TRUE)


# If PGX server not started, open terminal window and invoke the following
#  /u01/app/oracle/product/18.0.0/dbhome_1/md/property_graph/pgx/bin/./start-server

oaa.graphConnect(pgxBaseUrl = pgxBaseUrl,
                 dbHost=dbHost,
                 dbPort=dbPort,
                 dbUser=dbUser,
                 dbPassword=dbPassword,
                 dbServiceName=dbServiceName)

# How the table was created...(No need to do this, fyi only)

# Download tab-delimited data from
# http://www.cms.gov/apps/ama/license.asp?file=http://download.cms.gov/Research-Statistics-Data-and-Systems/Statistics-Trends-and-Reports/Medicare-Provider-Charge-Data/Downloads/Medicare_Provider_Util_Payment_PUF_CY2012_update.zip
# setwd("~/ORE")
# dat <- read.delim("~/ORE/Medicare_Provider_Util_Payment_PUF_CY2012.txt")
# ore.drop("MEDICARE")
# ore.create(dat ,table="MEDICARE")  # dat variable has loaded data from file
# ore.exec('alter table MEDICARE PARALLEL 32')
# ore.exec("CREATE INDEX MEDICARE_HCPCS_CODE_IDX on MEDICARE (HCPCS_CODE)")
# ore.exec("CREATE INDEX MEDICARE_NPI_IDX on MEDICARE (NPI)")
# ore.exec("CREATE INDEX MEDICARE_PROV_TYPE_IDX on MEDICARE (PROVIDER_TYPE)")

# view the tables in the database: MEDICARE_DATA
ore.ls(pattern="MED")

class(MEDICARE)    # table is an ore.frame proxy object
colnames(MEDICARE)
dim(MEDICARE)      # takes a few seconds to compute - it's a big table for a VM

# Derive providers demographic data table using OREdplyr

# National Provider Identifier (NPI),
# National Plan and Provider Enumeration System (NPPES)

medicare_providers <- MEDICARE %>%
  select ("NPI",                      "NPPES_PROVIDER_LAST_ORG_NAME",
          "NPPES_PROVIDER_FIRST_NAME","NPPES_PROVIDER_MI",       
          "NPPES_CREDENTIALS",        "NPPES_PROVIDER_GENDER",
          "NPPES_ENTITY_CODE",        "NPPES_PROVIDER_STREET1",     
          "NPPES_PROVIDER_STREET2",   "NPPES_PROVIDER_CITY",        
          "NPPES_PROVIDER_ZIP",       "NPPES_PROVIDER_STATE",       
          "NPPES_PROVIDER_COUNTRY",   "PROVIDER_TYPE") %>%
  distinct()
ore.drop("MEDICARE_PROVIDERS")
ore.create(medicare_providers,table="MEDICARE_PROVIDERS")  # materialize table in database
dim(MEDICARE_PROVIDERS)
head(MEDICARE_PROVIDERS)

#-- Visualization

# NPPES_PROVIDER_STATE and NPPES_PROVIDER_GENDER

res <- as.data.frame(with(MEDICARE_PROVIDERS,
                          table(NPPES_PROVIDER_STATE,    # use overloaded 'table' function
                                NPPES_PROVIDER_GENDER))) # for in-database computation

#-- Notice that CA and NY have the greatest number of providers

names(res) <- c("STATE","GENDER","COUNT")
ggplot(res, aes(reorder(STATE, COUNT), COUNT, fill=GENDER)) +
  geom_bar(stat = "identity", width=0.5) +
  scale_fill_brewer(palette="Paired") + xlab("STATE") +
  ggtitle("MEDICARE - Provider count by STATE and GENDER") + coord_flip()

# NPPES_PROVIDER_TYPE and NPPES_PROVIDER_GENDER

res <- as.data.frame(with(MEDICARE_PROVIDERS,
                          table(PROVIDER_TYPE,
                                NPPES_PROVIDER_GENDER)))

#-- Notice that Internal Medicine is the most popular specialty, followed by 
#--   Family Medine and Nurse Practitioner.  
#--   Some specialties have significant unbalanced gender

names(res) <- c("SPECIALTY","GENDER","COUNT")
ggplot(res, aes(reorder(SPECIALTY, COUNT), COUNT, fill=GENDER)) +
  geom_bar(stat = "identity", width=0.5) +
  scale_fill_brewer(palette="Paired") + xlab("SPECIALTY") +
  ggtitle("MEDICARE - Provider count by SPECIALTY and GENDER") + coord_flip()

# Total Medicare Payment for top 40 grossing Providers

MEDICARE$TOTAL_PAYMENT_AMT <-                 
  MEDICARE$LINE_SRVC_CNT*MEDICARE$AVERAGE_MEDICARE_PAYMENT_AMT # compute column in-database

res <- MEDICARE %>% group_by(NPI) %>% select(TOTAL_PAYMENT_AMT) %>%
  summarise(totalMedicarePayment = sum(TOTAL_PAYMENT_AMT,na.rm=TRUE)) %>%
  arrange(desc(totalMedicarePayment))

top40     <- ore.pull(head(res,40))
top40$NPI <- as.factor(top40$NPI)
top40$totalMedicarePayment <- round(top40$totalMedicarePayment)

#-- Notice that some providers have *very* high gross payments from Medicare
#--   what are their names?
ggplot(top40, aes(reorder(NPI,totalMedicarePayment), totalMedicarePayment)) +
  geom_bar(stat = "identity", width=0.6, fill="steelblue") +
  ggtitle("Total Medicare Payment for top 40 grossing Providers") +
  xlab("PROVIDER ID (NPI)") +
  geom_text(aes(label=totalMedicarePayment), hjust=1.1,
            color="white", size=3.0) +
  coord_flip()

######################################
# Graph Analytics
######################################

# Prepare Bipartite graph NODE and EDGE tables for OAAgraph using OREdplyr

# Produce NODE table with both providers and services

providers <- MEDICARE %>% distinct(NPI, NPPES_PROVIDER_LAST_ORG_NAME, PROVIDER_TYPE) %>%
  select(VID=NPI, LAST_NAME=NPPES_PROVIDER_LAST_ORG_NAME, SPECIALTY=PROVIDER_TYPE)

services <- MEDICARE %>% distinct(HCPCS_CODE, HCPCS_DESCRIPTION) %>% 
  inner_join(HCPCS_CODES, by="HCPCS_CODE") %>%
  select(VID=HCPCS_ID, HCPCS_CODE, DESCRIPTION=HCPCS_DESCRIPTION)

# Add complementary column set to enable single NODE table with labeled nodes
#   consisting of both providers and services provided
providers$LABEL       <- "PROVIDER"
providers$HCPCS_CODE  <- ""
providers$DESCRIPTION <- ""

services$LABEL        <- "SERVICE"
services$LAST_NAME    <- ""
services$SPECIALTY    <- ""
services <- services %>% select(VID,LAST_NAME, SPECIALTY,
                                LABEL, HCPCS_CODE, DESCRIPTION) # reorder columns to match providers

head(providers)
head(services)

## ** No need to recreate these tables if you don't want to wait **
## NODES <- rbind(ore.pull(providers), ore.pull(services)) # combine into single NODES data.frame
## ore.drop(table="MEDICARE_NODES")
## ore.create(NODES, table="MEDICARE_NODES")               # create common NODE table

dim(MEDICARE_NODES)

# Provide EDGE table with services provided

# This statement will take a minute or so to complete as it is working
# on 9M+ records

## ** No need to recreate these tables if you don't want to wait **
# serviceEdges <- MEDICARE %>%
#   inner_join(HCPCS_CODES, by="HCPCS_CODE") %>%  # use numeric HCPCS codes
#   select (EID=ID, SVID=NPI, DVID=HCPCS_ID,      # edge id, source vertex id, destination vertex id
#           DESCRIPTION=HCPCS_DESCRIPTION)        # assign column names per PGX reqs
#  
# serviceEdges$EL  <- "providesService"   # assign edge label (all edges the same)

## ** No need to recreate these tables if you don't want to wait **
# ore.drop(table="MEDICARE_EDGES")
# ore.create(serviceEdges, table = "MEDICARE_EDGES")  # create edge table in database
dim(MEDICARE_EDGES)
head(MEDICARE_EDGES)

# create graph from edges and nodes -- be patient (~220-480 sec.) as graph is large for this VM
system.time(graph <- oaa.graph(MEDICARE_EDGES, MEDICARE_NODES,
                               name="ProviderServicesGraph",
                               numConnections = 80))
graph  # view graph contents

## Set up for Personalized Page Rank algorithm for a single specialty

graph <- oaa.undirect(graph, keepMultiEdges = TRUE)     # make graph undirected for PPR

# Illustrate using one specialty, full solution performed for each specialty

s <- "Addiction Medicine"

# Get all providers (doctors) with specialty 's' and add to graph for PPR
vids <- ore.pull(MEDICARE_NODES %>% filter(SPECIALTY==s) %>% select (VID))$VID
vids
set  <- oaa.node.set(graph)
set  <- oaa.add(set, vids)

# Compute personalized page rank for graph using specific providers as starting points
res <- pagerank(graph, error=0.01, damping=0.85, maxIterations=1000,
                "personalized", nodeSet = set, name="pagerank")

# Get subgraph where provider speciality doesn't match selected set
subgraph <- oaa.subGraph(graph,paste("vertex.SPECIALTY !='", s,"'",sep=""),
                         type="nodes")

subgraph # view characteristics of result

# Select top 10 anomalous nodes from subgraph ranked by pagerank value
#  Note the use of PGQL for retrieving the result of interest
resultSet <- oaa.cursor(subgraph,
                        query = "select n.id(), n.SPECIALTY where (n), n.LABEL='PROVIDER',
                                    n.SPECIALTY !='Clinical Laboratory'
                                 order by n.pagerank desc
                                 limit 10")

suspects <- oaa.next(resultSet, 10)  # retrieve anomalous providers from cursor
names(suspects) <- c("VID","SPECIALTY")
 
suspectsSummary <- data.frame(specialtyGroup=s,
                              VID=suspects$VID,
                              SPECIALTY=suspects$SPECIALTY)
suspectsSummary


# make ore.frame row indexable
row.names(MEDICARE_PROVIDERS) <- MEDICARE_PROVIDERS$NPI  

# Find the name of one of the providers
MEDICARE_PROVIDERS %>% 
  filter(NPI==1770507931) %>% 
  select(NPPES_PROVIDER_LAST_ORG_NAME)

oaa.rm(graph)

##########################
### Machine Learning
##########################

# In contrast, use machine learning to identify anomalous transactions

# Anomaly Detection
build.cols <- c("NPI",
                "NPPES_PROVIDER_GENDER",
                "NPPES_ENTITY_CODE",
                "PROVIDER_TYPE",                 # a.k.a SPECIALTY
                "MEDICARE_PARTICIPATION_INDCTR",
                "PLACE_OF_SERVICE",
                "HCPCS_DRUG_INDICATOR",
                "LINE_SRVC_CNT",
                "BENE_UNIQUE_CNT",
                "BENE_DAY_SRVC_CNT",
                "AVERAGE_MEDICARE_ALLOWED_AMT",
                "STDEV_MEDICARE_ALLOWED_AMT",
                "AVERAGE_SUBMITTED_CHRG_AMT",
                "STDEV_SUBMITTED_CHRG_AMT",
                "AVERAGE_MEDICARE_PAYMENT_AMT",
                "STDEV_MEDICARE_PAYMENT_AMT")

#-- Build a Support Vector Machine anomaly detection model using "1-Class" SVM
system.time(mod.1csvm <- ore.odmSVM(~.-NPI, head(MEDICARE[,build.cols],10000),
                                    "anomaly.detection"))

pred.1csvm <- predict(mod.1csvm, head(MEDICARE,10000), 
                      c("NPI","PROVIDER_TYPE"), type="class")

ore.drop("MEDICARE_1CSVM_PRED")
system.time(ore.create(pred.1csvm, table="MEDICARE_1CSVM_PRED")) # actually compute scores

table(MEDICARE_1CSVM_PRED$PREDICTION)   # how many anomalies (value == 0)

# Count number of anomalous records by provider type (specialty)
res <- MEDICARE_1CSVM_PRED %>% filter(PREDICTION==0) %>%
  select(PROVIDER_TYPE) %>% group_by(PROVIDER_TYPE) %>%
  count(PROVIDER_TYPE, sort=TRUE) %>% select(SPECIALTY=PROVIDER_TYPE,COUNT=n)
res <- ore.pull(res)
ggplot(res, aes(reorder(SPECIALTY, COUNT), COUNT)) +
  geom_bar(stat = "identity", width=0.5, fill="steelblue") + xlab("SPECIALTY") +
  ggtitle("Anomaly Count by SPECIALTY") + coord_flip()

hist(MEDICARE_1CSVM_PRED$PROBABILITY, col="steelblue")      # view distribution of anomaly probs
anomalies <- subset(MEDICARE_1CSVM_PRED, PROBABILITY > .70) # select higher prob anomalies
head(anomalies)
dim(anomalies)

# Count number of anomalous records by provider (NPI) and specialty
res <- MEDICARE_1CSVM_PRED %>% filter(PROBABILITY > .70) %>%
  select(NPI, PROVIDER_TYPE) %>% group_by(NPI, PROVIDER_TYPE) %>%
  count(NPI, PROVIDER_TYPE, sort=TRUE) %>% select(NPI,SPECIALTY=PROVIDER_TYPE, COUNT=n)
head(res)
dim(res)

res1 <- res %>% group_by(SPECIALTY) %>% summarise(COUNT=sum(COUNT))

res1 <- ore.pull(res1)
ggplot(res1, aes(reorder(SPECIALTY, COUNT), COUNT)) +
  geom_bar(stat = "identity", width=0.5, fill="steelblue") + xlab("SPECIALTY") +
  geom_text(aes(label=COUNT), hjust=.03, color="black", size=3.5) +
  ggtitle("Filtered Anomaly Count by SPECIALTY") + coord_flip()

# Housekeeping

detach(package:OAAgraph, unload=TRUE)
rm(list = ls())
ore.disconnect()

##################################
# End of Script
##################################