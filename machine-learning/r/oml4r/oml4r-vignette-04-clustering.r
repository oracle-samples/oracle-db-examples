################################################
##
## Oracle Machine Learning for R Vignettes
##
## Clustering
##
## Copyright (c) 2020 Oracle Corporation                          
##
## The Universal Permissive License (UPL), Version 1.0
## 
## https://oss.oracle.com/licenses/upl/
##
################################################
# In this vignette, we explore clustering on generated data and the AUTO data set. 
#
# We will highlight a few aspects of ORE: 
# 
#   * Data Access          - creating database tables from R data.frames
#   * Visualize Data       - using open source R
#   * Predictive Analytics - using ore.odmKMeans and ore.odmOC funtions to build models
#   * Embedded R Execution - illustrate how to produce this result at the database server from R

# Load the ORE library

library(ORE)

# Turn off row ordering warnings
options(ore.warn.order=FALSE)

# Create an ORE Connection
ore.connect(user        ="rquser",
            conn_string ="OAA1",
            host        ="localhost",
            password    ="rquser",
            all         =TRUE)

rm(list = ls())  # housekeeping

###########################
# create demo data set
###########################

set.seed(123)        # enable repeatable results
options(digits=4)    # limit decimal output

#-- generate a data set with three clusters

dat <- rbind(matrix(rnorm(1000, sd = 0.3), ncol = 2),              # cluster 1
             matrix(rnorm(1000, mean = 1, sd = 0.3), ncol = 2),    # cluster 2
             matrix(rnorm(1000, mean = 2.5, sd = 0.4), ncol = 2))  # cluster 3
colnames(dat) <- c("x", "y")
dat <- data.frame(dat)

#-- view the clusters

plot(dat$x, dat$y)

#-- create a temporary database table using ore.push - object deleted when db connection ends

X <- ore.push (data.frame(dat))   

class(X)

######################################################
# Build, score and visualize with k-Means clustering
######################################################

#-- Build a k-means clustering model with 3 clustered required

km.mod1 <- ore.odmKMeans(~., X,
                         num.centers=3,
                         num.bins=5)

summary(km.mod1)                                 # view the model summary

#-- Use model to assign clusters to rows

km.res1 <- predict(km.mod1,X,type="class", supplemental.cols=c("x","y"))

head(km.res1,3)                                  # view assignments

#-- Visualize the cluster assignments and centroids

km.res1.local <- ore.pull(km.res1)               # retrieve data from database for visualization

plot(data.frame(x=km.res1.local$x, y=km.res1.local$y), col=km.res1.local$CLUSTER_ID)
points(km.mod1$centers2, col = "black", pch = 8, cex=5)  # plot the cluster centroids

#-- Score data retrieving different details

head(predict(km.mod1,X))        # view default prediction output
tail(predict(km.mod1,X,type=c("class","raw"),supplemental.cols=c("x","y")),3)  # ask for additional columns to be returned
tail(predict(km.mod1,X,type="raw",supplemental.cols=c("x","y")),3)             # ask for only raw probabilities with supp data

###################################################
# Use Oracle Orthoginal Partitioning Clustering 
# density-based algorithm
###################################################

###########################
# create demo data set
###########################

#-- generate a data set with three clusters

dat <- rbind(matrix(rnorm(1000, sd = 0.3)+5, ncol = 2),
             matrix(rnorm(1000, mean = 1.5, sd = 0.4)+5, ncol = 2),
             matrix(rnorm(1000, mean = 2.5, sd = 0.4), ncol = 2))
colnames(dat) <- c("x", "y")
dat <- data.frame(dat)

#-- view the clusters

plot(dat$x, dat$y)

#-- create a temporary database table using ore.push

X <- ore.push (data.frame(dat))  

######################################################
# Build, score and visualize with O-Cluster clustering
######################################################

#-- Build the Orthogonal Partitioning Clustering model with max of 5 clustered

oc.mod1 <- ore.odmOC(~., X, num.centers=5)    # Ask for upper limit of clusters
summary(oc.mod1)

#-- Use model to assign clusters to rows

oc.res1 <- predict(oc.mod1,X,type="class",   
                   supplemental.cols=c("x","y"))

head(oc.res1,3)                               # view assignments

oc.res1.local <- ore.pull(oc.res1)            # retrieve data from database for visualization

#-- Visualize the cluster assignments and centroids

plot(data.frame(x=oc.res1.local$x,
                y=oc.res1.local$y),
     col=oc.res1.local$CLUSTER_ID)
points(oc.mod1$centers2,                      # plot the cluster centroids
       col = "black", #rownames(oc.mod1$centers2),
       pch = 8, cex=8)

oc.mod1$centers2                              # view the centroids

########################################################
## Auto data -- based on real data for 3D Visualization
########################################################

library(ISLR)
Auto2 <- Auto
Auto2$origin    <- as.factor(Auto2$origin)   # adjust data representation
Auto2$name      <- as.character(Auto2$name)
str(Auto2)

#-- create table in database

ore.drop(table="AUTO")
ore.create(Auto2, table="AUTO") 

ore.ls(pattern="AUTO")   # view the data
class(AUTO)              # ore.frame
head(AUTO)

#-- Build k-Means clustering model on three variables and 4 centers

km.mod1 <- ore.odmKMeans(~mpg+displacement+horsepower, AUTO, num.centers=4,
                         num.bins=10, iterations=30, split.criterion = "variance")
summary(km.mod1)
km.mod1$name   # get the name of the model as it exists in the database (view in ODMr)

#-- Use model to assign clusters to rows

km.res1 <- predict(km.mod1,AUTO,type="class",
                   supplemental.cols=c("name","mpg","displacement","horsepower","cylinders"))

#-- Explore the clusters

head(km.res1,3)                                      # view cluster assignments
split.clusters <- split(km.res1,km.res1$CLUSTER_ID)  # explore each cluster
lapply(split.clusters, nrow)                         # count number of cars assigned to each cluster
lapply(split.clusters, summary)                      # get summary statistics on each cluster

km.res1.local <- ore.pull(km.res1)                   # retrieve data for visualization


#-- Visualize the clustering using a ggplot2

library(ggplot2)

# Use a facet wrap to understand how clusters relate to displacement, horsepower and cylinders
ggplot(km.res1.local, aes(displacement, horsepower, colour=as.factor(CLUSTER_ID))) + 
  geom_point() + facet_wrap("cylinders")

# Use a facet wrap to understand how clusters relate to mpg, horsepower and cylinders
ggplot(km.res1.local, aes(mpg, horsepower, colour=as.factor(CLUSTER_ID))) + 
  geom_point(aes(size=displacement), alpha=0.2) + facet_wrap("cylinders") + 
  ggtitle("MPG x Horsepower with sized displacement and Cluster Assignment")

#...but two dimensions can be limiting -- try a 3D plot



#-- Visualize the clustering using a 3D plot

library(plot3D)

with(km.res1.local, scatter3D(mpg, displacement, horsepower, phi = 10, bty = "g",
                              colvar=CLUSTER_ID, col=unique(CLUSTER_ID),
                              xlab="mpg", ylab="displacement", zlab="horsepower",
                              colkey=FALSE, main="Clustering of Horsepower, MPG, and Displacement",
                              pch = 20, cex = 1.5, ticktype = "detailed"))

# Change perspective of 3D space

with(km.res1.local, scatter3D(mpg, displacement, horsepower, phi = 20, theta = 70, bty = "g",
                              colvar=CLUSTER_ID, col=unique(CLUSTER_ID),
                              xlab="mpg", ylab="displacement", zlab="horsepower",
                              colkey=FALSE, main="Clustering of Horsepower, MPG, and Displacement",
                              pch = 20, cex = 1.5, ticktype = "detailed"))

#-- STOP: Try with ODMr
# See ODMr workflow "OAA Demos -> OAA Vignette - Clustering", which generates a k-means, O-cluster, and Expectation Maximization
#     clustering model using same input / settings
# generate scoring output with columns as above
# then use R to generate 3D plot

ore.sync()                        # sync ore.frame data since table created outside of ORE
head(CLUSTERING_ODMR_OUT,3)       # view table

res.local <- ore.pull(CLUSTERING_ODMR_OUT)  # pull data for visualization
colnames(res.local)

#-- View clustering using k-Means model

with(res.local,
     scatter3D(mpg, displacement, horsepower, phi = 10, bty = "g",
               colvar=CLUS_KM_2_1_CLID,col=unique(CLUS_KM_2_1_CLID),
               xlab="mpg", ylab="displacement", zlab="horsepower",
               colkey=FALSE, main="KM Clustering of Horsepower, MPG, and Displacement",
               pch = 20, cex = 1.0, ticktype = "detailed"))

#-- View clustering using O-Cluster model

# Note: density-based algorithm not appropriate for this data - single cluster found
with(res.local,
     scatter3D(mpg, displacement, horsepower, phi = 10, bty = "g",
               colvar=CLUS_OC_2_1_CLID,col=unique(CLUS_OC_2_1_CLID),
               xlab="mpg", ylab="displacement", zlab="horsepower",
               colkey=FALSE, main="OC Clustering of Horsepower, MPG, and Displacement",
               pch = 20, cex = 1.0, ticktype = "detailed"))

#-- View clustering using EM model

with(res.local,
     scatter3D(mpg, displacement, horsepower, phi = 10, bty = "g",
               colvar=CLUS_EM_2_1_CLID,col=unique(CLUS_EM_2_1_CLID),
               xlab="mpg", ylab="displacement", zlab="horsepower",
               colkey=FALSE, main="EM Clustering of Horsepower, MPG, and Displacement",
               pch = 20, cex = 1.0, ticktype = "detailed"))

#########################################################
## Generate plots using Embedded R Execution
##    On the database server side, build a KMeans
##    model, predict cluster assignments, then generate
##    3D plot
#########################################################

f <- function() {
  ore.sync(table="AUTO")
  ore.attach()
  km.mod1 <- ore.odmKMeans(~mpg+displacement+horsepower, AUTO, num.centers=4,
                           num.bins=10, iterations=30, split.criterion = "variance")
  km.res1 <- predict(km.mod1,AUTO,type="class",
                     supplemental.cols=c("name","mpg","displacement","horsepower","cylinders"))
  km.res1.local <- ore.pull(km.res1)
  library(plot3D)
  with(km.res1.local, scatter3D(mpg, displacement, horsepower, phi = 10, bty = "g",
                                colvar=CLUSTER_ID, col=unique(CLUSTER_ID),
                                xlab="mpg", ylab="displacement", zlab="horsepower",
                                colkey=FALSE, main="Clustering of Horsepower, MPG, and Displacement",
                                pch = 20, cex = 1.5, ticktype = "detailed"))
  invisible()
}

# NOTE: All previous graphics will be deleted
dev.off()


res <- ore.doEval(f,ore.connect = TRUE)
res

# NOTE: All previous graphics will be deleted
dev.off()

#-- Create the script in the R Script repository with name "Clustering_AUTO"
#--   and execute using embedded R execution by name

ore.scriptCreate("Clustering_AUTO", f, overwrite=TRUE)
res <- ore.doEval(FUN.NAME="Clustering_AUTO", ore.connect=TRUE)
res

#-- STOP: Go to SQL Developer in script '~/ORE/oml4r-vignette-04-clustering.sql' 
#-- and invoke function from SQL

# select * 
# from table(rqEval(cursor(select 1 "ore.connect" from dual),
#                   'PNG',
#                   'Clustering_AUTO'));

# Cleanup -- DO NOT RUN until you completed the SQL Developer execution
ore.scriptDrop("Clustering_AUTO")
ore.drop(table="CLUSTERING_ODMR_OUT")
rm(list = ls()) 
ore.disconnect()


################################################
## End of Script
################################################
