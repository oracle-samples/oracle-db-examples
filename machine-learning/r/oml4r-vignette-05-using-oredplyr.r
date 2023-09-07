################################################
##
## Oracle Machine Learning for R Vignettes
##
## Using OREdeplyr
## Content adapted from dplyr vignettes
##
## Copyright (c) 2020 Oracle Corporation                          
##
## The Universal Permissive License (UPL), Version 1.0
## 
## https://oss.oracle.com/licenses/upl/
##
################################################
# Load the ORE library
library(ORE)

# Turn off row ordering warnings
options(ore.warn.order=FALSE)

?ore.connect  # View documentation on ore.connect

# Create an ORE Connection
ore.connect(user="rquser",
            conn_string="OAA1",
            host="localhost",
            password="rquser",
            all=TRUE)

ore.ls()  # list available tables

library(OREdplyr)       # OREdplyr must be explicitly loaded to use

library(nycflights13)   # contains data sets for this script

head(flights)           # view a few rows of each data set
head(airlines)
head(airports)
head(planes)
head(weather)

####################################
# Import data to Oracle Database
####################################

ore.drop("FLIGHTS")                                 # remove database table, if exists
ore.create(as.data.frame(flights), table="FLIGHTS") # create table from data.frame as ore.frame

dim(FLIGHTS)       # get # rows and # columns
colnames(FLIGHTS)  # view names of columns
head(FLIGHTS)      # verify data.frame appears as expected in database table FLIGHTS

####################
# Basic operations
####################

select(FLIGHTS, year, month, day, dep_delay, arr_delay) %>% head() # select columns
select(FLIGHTS, -year,-month, -day) %>% head()                     # exclude columns

select(FLIGHTS, tail_num = tailnum) %>% head()                     # rename columns, but drops others
rename(FLIGHTS, tail_num = tailnum) %>% head()                     # rename columns

filter(FLIGHTS, month == 1, day == 1) %>% head()                   # filter rows
filter(FLIGHTS, dep_delay > 240) %>% head()
filter(FLIGHTS, month == 1 | month == 2) %>% head()

arrange(FLIGHTS, year, month, day) %>% head()                      # sort rows by specified columns
arrange(FLIGHTS, desc(arr_delay)) %>% head()                       # sort in descending order

distinct(FLIGHTS, tailnum) %>% head()                              # see distinct values
distinct(FLIGHTS, origin, dest) %>% head()                         # see distinct pairs

mutate(FLIGHTS, speed = air_time / distance) %>% head()            # compute and add new columns
mutate(FLIGHTS,                                          # keeps existing columns
            gain = arr_delay - dep_delay,
            speed = distance / air_time * 60) %>% head()

transmute(FLIGHTS,                                       # only keeps new computed columns
               gain = arr_delay - dep_delay,
               gain_per_hour = (arr_delay - dep_delay) / (air_time / 60)
) %>% head()

summarise(FLIGHTS,
          mean_delay = mean(dep_time,na.rm=TRUE),  # aggregates the specified column values
          min_delay = min(dep_time,na.rm=TRUE),
          max_delay = max(dep_time,na.rm=TRUE),
          sd_delay = sd(dep_time,na.rm=TRUE))        

FLIGHTS[1,]                             # Row indexing *fails* unless enabled with row.names or primary key
row.names(FLIGHTS) <- FLIGHTS$tailnum   # specify row.names to enable row indexing
FLIGHTS[1,]                             # Row indexing enabled

slice(FLIGHTS, 10:20)                   # requires ordered ore.frame, returns specified rows

sample_n(FLIGHTS, 10)                   # take a random sample of N rows
dim(sample_frac(FLIGHTS, 0.01))         # take a random sample of p %

sample_n(FLIGHTS, 10, replace = TRUE)   # take a random sample of N rows with replacement

#########################################
# Stacking operations - lazy evaluation
#########################################

c1 <- filter(FLIGHTS, year == 2013, month == 1, day == 1)                  # filter rows
c2 <- select(c1, year, month, day, carrier, dep_delay, air_time, distance) # select columns
c3 <- mutate(c2, speed = distance / air_time * 60)                         # compute column
c4 <- arrange(c3, year, month, day, carrier)                               # sort result
head(c4)
dim(c4)
class(c4)

#-- Retrieve all the data to a local data.frame

c4_local <- ore.pull(c4)   # as opposed to 'collect' from dplyr
dim(c4_local)
class(c4_local)

#################
# Grouping
#################

by_tailnum <- group_by(FLIGHTS, tailnum)  # group data by tailnum
head(by_tailnum)
delay <- summarise(by_tailnum,            # For each tailnum, compute count, avg distance and arrival delay
                   count = n(),
                   dist = mean(distance,na.rm=TRUE),
                   delay = mean(arr_delay,na.rm=TRUE)
)
head(delay)
delay <- filter(delay, count > 20, dist < 2000)       # filter rows by count and distance
head(delay)


# Note, average delay is only slightly related to the average distance flown by a plane
library(ggplot2)
delay.local <- ore.pull (delay)  # pull data to client to generate plot
ggplot(delay.local, aes(dist, delay)) +
  geom_point(aes(size = count), alpha = 1/2, color='darkgreen') +
  geom_smooth() +
  scale_size_area()


monthly <- group_by(FLIGHTS, year, month)               # group by year and month

# Find the most and least delayed flight each month
bestworst <- monthly %>%
  select(year, month, flight, arr_delay) %>%
  filter(min_rank(arr_delay) == 1 | min_rank(desc(arr_delay)) == 1)
bestworst %>% arrange(month, arr_delay)


# Rank each flight within the month
ranked <- monthly %>%
  select(arr_delay,year,month) %>%
  mutate(rank = rank(desc(arr_delay)))
head(ranked)
class(ranked)

ranked_sorted <- arrange(ranked, rank)        # sort data by rank
head(ranked_sorted)

destinations <- group_by(FLIGHTS, dest)       # group by destination

daily <- group_by(FLIGHTS, year, month, day)  # determine number of flights per day
per_day   <- summarise(daily, flights = n())
head(per_day)

(per_month <- summarise(per_day, flights = sum(flights)))   # number of flights per month

(per_year  <- summarise(per_month, flights = sum(flights))) # number of flights per year


####################
# Chaining
####################

a1 <- group_by(FLIGHTS, year, month, day)
a2 <- select(a1, arr_delay, dep_delay)
a3 <- summarise(a2,                  
                arr = mean(arr_delay, na.rm = TRUE),
                dep = mean(dep_delay, na.rm = TRUE))
a4 <- filter(a3, arr > 30 | dep > 30)
head(a4)

res <- filter( 
  summarise(
    select(
      group_by(FLIGHTS, year, month, day),
      arr_delay, dep_delay
    ),
    arr = mean(arr_delay, na.rm = TRUE),
    dep = mean(dep_delay, na.rm = TRUE)
  ),
  arr > 30 | dep > 30
)
head(res)

res <- FLIGHTS %>%  
  group_by(year, month, day) %>%
  select(arr_delay, dep_delay) %>%
  summarise(
    arr = mean(arr_delay, na.rm = TRUE),
    dep = mean(dep_delay, na.rm = TRUE)
  ) %>%
  filter(arr > 30 | dep > 30)
head(res)

#####################
# Tally and count
#####################

ore.drop("MTCARS")
ore.create(mtcars, table="MTCARS")

arrange(tally(group_by(MTCARS, cyl)), cyl)  # count of number of cars by # cylinders, sort by # cylinders
tally(group_by(MTCARS, cyl), sort = TRUE)   # same, but sort by count

#-- Multiple tallys progressively roll up the groups

cyl_by_gear <- tally(group_by(MTCARS, cyl, gear), sort = TRUE)
tally(cyl_by_gear, sort = TRUE)
tally(tally(cyl_by_gear))

cyl_by_gear <- tally(group_by(MTCARS, cyl, gear), wt = hp,  sort = TRUE)
tally(cyl_by_gear, sort = TRUE)
tally(tally(cyl_by_gear))

cyl_by_gear <- count(MTCARS, cyl, gear, wt = hp + mpg, sort = TRUE)
tally(cyl_by_gear, sort = TRUE)
tally(tally(cyl_by_gear))

MTCARS %>% group_by(cyl) %>% tally(sort = TRUE)

# count is more succinct and also performs grouping
MTCARS %>% count(cyl) %>% arrange(cyl)

MTCARS %>% count(cyl, wt = hp) %>% arrange(cyl)

MTCARS[MTCARS$cyl==4, "hp"]         # how is the value for cyl==4 computed?
sum(MTCARS[MTCARS$cyl==4, "hp"])    # Note: same number

MTCARS %>% count_("cyl", wt = hp, sort = TRUE)

#-- Grouped tally

tally(group_by(FLIGHTS, month))                 # count of flights per month
tally(group_by(FLIGHTS, month), sort = TRUE)    # same, sorted by count

#-- Nested tally invocations progressively roll up the groups

origin_by_month <- tally(group_by(FLIGHTS, origin, month), sort = TRUE)
tally(origin_by_month, sort = TRUE)
tally(tally(origin_by_month))

# Use the infix %>% operator
FLIGHTS %>% group_by(month) %>% tally(sort = TRUE)

# count is even more succinct - it also does the grouping for you
FLIGHTS %>% count(month,sort=TRUE)


#################
# Non-Standard Evaluation (NSE) vs Standard Evaluation (SE)
#################

# NSE version:
summarise(MTCARS, mean(mpg))

# SE versions:
summarise_(MTCARS, ~mean(mpg))

summarise_(MTCARS, quote(mean(mpg)))

summarise_(MTCARS, "mean(mpg)")

n <- 10
dots <- list(~mean(mpg), ~n)
summarise_(MTCARS, .dots = dots)


#################################
# Two table functions - Joins
#################################

# create the needed tables from the nycflights13 data sets
ore.drop("AIRLINES")
ore.create(as.data.frame(airlines), table="AIRLINES")
dim(AIRLINES)
head(AIRLINES)

ore.drop("WEATHER")
ore.create(as.data.frame(weather), table="WEATHER")
dim(WEATHER)
head(WEATHER)

ore.drop("PLANES")
ore.create(as.data.frame(planes), table="PLANES")
dim(PLANES)
head(PLANES)

ore.drop("AIRPORTS")
ore.create(as.data.frame(airports), table="AIRPORTS")
dim(AIRPORTS)
head(AIRPORTS)

#-- select subset of columns for the following examples

flights2 <- FLIGHTS %>% select(year,month,day, hour, origin, dest, tailnum, carrier)
head(flights2)
dim(flights2)

# create a database table index, if desired
ore.exec('CREATE INDEX carrier_idx on FLIGHTS("carrier")')  

res <- flights2 %>% left_join(AIRLINES)   # joins on carrier - "natural join"
head(res)
dim(res)

res <- flights2 %>% left_join(WEATHER)    # joins on year, month, day, origin - "natural join"
head(res)
dim(res)

res <- flights2 %>% left_join(PLANES, by = "tailnum")  # specify column to join by
head(res)
dim(res)

res <- flights2 %>% left_join(AIRPORTS, c("dest" = "faa")) # specify which columns to join
head(res)
dim(res)

res <- flights2 %>% left_join(AIRPORTS, c("origin" = "faa")) # join on origin instead of dest
head(res)
dim(res)

####################################
# Other join-related functions
####################################

(df1 <- data_frame(x = c(1, 2), y = 2:1))         # create some data
(df2 <- data_frame(x = c(1, 3), a = 10, b = "a"))

ore.drop("DF1")                                   # store in the database as tables
ore.create(as.data.frame(df1), table="DF1")
ore.drop("DF2")
ore.create(as.data.frame(df2), table="DF2")

DF1 %>% inner_join(DF2)   # returns rows when there is a match in both tables

DF1 %>% left_join(DF2)    # returns all rows from the left table, even if no matches in the right table

DF1 %>% right_join(DF2)   # returns all rows from the right table, even if no matches in the right table

DF2 %>% left_join(DF1)    # swap the tables and see different, but similar results on a per row basis

DF1 %>% full_join(DF2)    # returns all rows from the left and right tables. Combines the result of both LEFT and RIGHT joins

# housekeeping

rm(list=ls())
ore.drop(table="AIRLINES")
ore.drop(table="AIRPORTS")
ore.drop(table="DF1")
ore.drop(table="DF2")
ore.drop(table="FLIGHTS")
ore.drop(table="MTCARS")
ore.drop(table="WEATHER")
ore.drop(table="PLANES")
ore.disconnect()

################################################
## End of Script
################################################


