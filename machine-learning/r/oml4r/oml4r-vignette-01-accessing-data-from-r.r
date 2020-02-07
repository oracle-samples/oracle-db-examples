################################################
##
## Oracle Machine Learning for R Vignettes
## Accessing Data from R
##
## (c) 2020 Oracle Corporation
##
################################################

# Source data: https://www.kaggle.com/harlfoxem/d/harlfoxem/housesalesprediction/house-price-prediction-part-1


library(ORE)                   # Load the ORE library
options(ore.warn.order=FALSE)  # Turn off ordering warnings
par(mar=c(5.1,4.1,4.1,2.1))    # set margin for plots
?ore.connect                   # View documentation on ore.connect

# Database Login details
conn.string   <- "OAA1"
hostname      <- "localhost"
user          <- "rquser"
password      <- "rquser"
all.tables    <- TRUE

# Create an ORE Connection
ore.connect(user=user,conn_string=conn.string,host=hostname,
            password=password, all=all.tables)

rm(list = ls())  # housekeeping

#################################################
# Load the dataset and 
# create a database table from a CSV file in R
#################################################

setwd("/home/oracle/ORE")               # Set working directory where data file resides
house <- read.csv("kc_house_data.csv")    # Load the data into R memory, creating a data.frame

library(data.table)
house <- fread("kc_house_data.csv")       # Load the data using data.table's fread

colnames(house)    # Verify that data loaded correctly
head(house)     # View a few rows
str(house)      # See the data types associated with columns and adjust

house$id         <- as.character(house$id)      # Convert id to character string
house$date       <- substr(house$date,1,8)      # Reduce date to minimal length required
house$zipcode    <- as.factor(house$zipcode)    # Convert zipcode from number to factor
house$waterfront <- as.factor(house$waterfront) # Convert waterfront from number to factor
house$view       <- as.factor(house$view)       # Convert view from number to factor
house$condition  <- as.factor(house$condition)  # Convert condition from number to factor
house$grade      <- as.factor(house$grade)      # Convert grade from number to factor

str(house)      # See adjusted data types

ore.drop(table="HOUSE")          # Drop pre-existing database table with dataTableName
ore.create(house, table="HOUSE") # Create database table with dataTableName using data.frame
ore.ls(pattern="HO")             # List tables matching pattern

head(HOUSE,4)   # Variable created to reference ore.frame as proxy for database table HOUSE

HOUSE@desc      # View variable names and data types

#################################################
## Exploring Data: Descriptive Statistics
#################################################

dim(HOUSE)                # View number of rows and columns, computed in-database

summary(HOUSE)            # View summary statistics, computed in-database

summary(HOUSE[,c(3:5)])   # Use standard R syntax to select columns

numericVars <- HOUSE@desc[HOUSE@desc$Sclass=="numeric" | HOUSE@desc$Sclass=="integer",
                          "name"]
statsComputed <- c("n","mean","stddev","min","p25","p50","p75","max")

statsRes <- ore.summary(HOUSE, var=numericVars, stats=statsComputed)

res <- data.frame(numericVars, matrix(ore.pull(statsRes)[,-1], 
                                      length(numericVars),length(statsComputed)))
names(res) <- c("colName",statsComputed)
res

#######################################################################
# Visualization using overloaded R functions on ore.frames
#######################################################################

# Maps

summary(HOUSE$lat)
summary(HOUSE$long)

# Comment: use ggplot2 for charting

library(ggplot2)
qplot(lat,long,data=house,col="red") # simple plot using lat/long only

# Use ORE Embedded R Execution to compute aggregates in parallel

# Aggregate by zipcode - compute mean price, #BR, #Baths, #homes in zip

res <- ore.groupApply(HOUSE, INDEX=HOUSE$zipcode, 
                      function(dat) {
                        zip <- dat[1,"zipcode"]
                        m_price     <- mean(dat$price,na.rm=TRUE)
                        m_bedrooms  <- mean(dat$bedrooms,na.rm=TRUE)
                        m_bathrooms <- mean(dat$bathrooms,na.rm=TRUE)
                        count       <- nrow(dat)
                        data.frame(zipcode=zip, price=m_price, bedrooms=m_bedrooms, bathrooms=m_bathrooms,count=count)
                      },
                      FUN.VALUE=data.frame(zipcode="a", price=1, bedrooms=1, bathrooms=1,count=1)
                     )
head(res)

# Exploring the target - house price
options(scipen=10)
par(mar=c(5.1,4.1,4.1,2.1))    # set margin for plots

boxplot(HOUSE$price, horizontal = TRUE, col="blue", 
        main="Distribution of house price")
points(mean(HOUSE$price),1, col="red",pch=18)

# Associations and Correlations

# http://rpubs.com/jmount/WVPlots

# NOTE: the following plots may take a few seconds to render due to number of points

# devtools::install_github("WinVector/WVPlots")
library(WVPlots)
simpleRandomSample <- sample(1:nrow(HOUSE),nrow(HOUSE) * 0.1) # sample data for faster plots
row.names(HOUSE) <- HOUSE$id

hh <- ore.pull(HOUSE[simpleRandomSample,])
dim(hh)
ScatterHist(hh, "sqft_living", "price",title="House price by sqft living space")
ScatterHist(hh, "yr_built", "price",title="House price by year built")

ScatterHist(hh, "sqft_basement", "price",title="House price by sqft basement space")
ScatterHist(hh, "yr_renovated", "price",title="House price by year renovated")

# Notice that the two plots above include many zero values, esp. yr_renovated

# Clean data for basement sqft and renovated to replace zeros with NA

HOUSE$sqft_basement2 <- ifelse(HOUSE$sqft_basement>0,HOUSE$sqft_basement,NA)
HOUSE$yr_renovated2 <- ifelse(HOUSE$yr_renovated>0,HOUSE$yr_renovated,NA)
hh <- ore.pull(HOUSE[simpleRandomSample,])

ScatterHist(hh, "sqft_basement2", "price",title="House price by sqft basement space")
ScatterHist(hh, "yr_renovated2", "price",title="House price by year renovated")

# Create indicator variables as to whether a house has a basement or was renovated

HOUSE$basement  <- ifelse(HOUSE$sqft_basement>0, TRUE, FALSE)
HOUSE$renovated <- ifelse(HOUSE$yr_renovated>0, TRUE, FALSE)

# Categorical Variables

?boxplot # see definition of 'varwidth'

boxplot(price~waterfront,ore.pull(HOUSE), horizontal=TRUE, col="darkblue",
        varwidth=TRUE, main="Distribution of price by waterfront")
points(mean(HOUSE[HOUSE$waterfront==1,]$price),2, col="red",pch=18)
points(mean(HOUSE[HOUSE$waterfront==0,]$price),1, col="red",pch=18)

library(colorspace)

boxplot(price~bedrooms,hh, horizontal=TRUE, col=rainbow_hcl(length(unique(HOUSE$bedrooms))),
        main="Distribution of price by number of bedrooms")
boxplot(price~bathrooms,hh, horizontal=TRUE, col=rainbow_hcl(length(unique(HOUSE$bathrooms))),
        main="Distribution of price by number of bathrooms")
boxplot(price~grade,hh, horizontal=TRUE, col=rainbow_hcl(length(unique(HOUSE$grade))),
        main="Distribution of price by grade")

# Notice the grade values are not in numeric order, change factor  levels explicitly
levels(hh$grade)
hh$grade <- factor(hh$grade,levels(hh$grade)[c(6,8:10,1:2,7,3:5)])

boxplot(price~grade,hh, horizontal=TRUE, col=rainbow_hcl(length(unique(HOUSE$grade))),
        main="Distribution of price by grade")

# Correlation

row.names(HOUSE) <- HOUSE$id
cor.res <- data.frame(variable=c("Bedrooms","Bathrooms","Floors","View","Condition","Grade"),
                      cor_with_price = c(with(HOUSE, cor(price, bedrooms, method="spearman")),
                                         with(HOUSE, cor(price, bathrooms, method="spearman")),
                                         with(HOUSE, cor(price, as.numeric(floors), method="spearman")),
                                         with(HOUSE, cor(price, as.numeric(view), method="spearman")),
                                         with(HOUSE, cor(price, as.numeric(condition), method="spearman")),
                                         with(HOUSE, cor(price, as.numeric(grade), method="spearman"))))
cor.res

# Using standard R graphics with an ore.frame proxy object

hist(HOUSE$price, col="red")
hist(HOUSE$price, breaks=100, col="red") # See finer granularity histogram

hist(HOUSE$yr_built, col="darkgreen") # See coarse view of when homes were built

HOUSE.split.yr_built <- with(HOUSE, split(price, yr_built)) # partition data by year built

x <- sapply(HOUSE.split.yr_built, length)  # See how many homes built in each year
x
barplot(x,col="blue") # notice the drop in houses built around The Great Depression (1930s)


boxplot(HOUSE.split.yr_built, col = "blue", cex=0.5, varwidth = TRUE) # view distribution of price with outliers

subset.HOUSE <- subset(HOUSE, price < 500000 & yr_built > 1980)  # Remove some outliers to get more detail an dfocus on last ~30 years
HOUSE.split.yr_built <- with(subset.HOUSE,split(price, yr_built)) # partition data by year built
boxplot(HOUSE.split.yr_built, col = "blue") # view distribution of price with outliers

#-- explore selected variables using enhanced pairs plot 
#-- visually look for correlations among pairs of variables
#-- sample 10% of data to speed up plot generation, with similar trends evident
#-- NOTE: this will take several seconds to render due to volume of data

simpleRandomSample <- sample(1:nrow(HOUSE),nrow(HOUSE) * 0.1)
row.names(HOUSE) <- HOUSE$id
pairs(HOUSE[simpleRandomSample,numericVars[1:9]],  # select sampled rows and exclude 'id' and 'date' columns
      panel=function(x,y) {
        points(x,y,col="darkgray")
        abline(lm(y~x), lty="dashed",col="red") # compute linear model
        lines(lowess(x,y),col="green")},        # display lowess curve
      diag.panel=function(x) {
        par(new=TRUE)
        hist(x, main="",breaks=40,axes=FALSE,col="blue")} # generate histogram
)

# housekeeping

rm(list=ls())
ore.drop(table="HOUSE")
ore.disconnect()

################################################
## End of Script
################################################





