################################################
##
## Oracle Machine Learning for R Vignettes
##
## Text Analysis with Explicit Semantic Analysis (ESA)
##
## (c) 2020 Oracle Corporation
##
################################################

# In this vignette, we explore text analytics using the Explicit Semantic Analysis
# algorithm to extract features from a sample data set. Then, we use the 
# ESA model that was pre-built on millions of Wikipedia articles and reduced to 
# 200,000 topics. 
#
# We will highlight a few aspects of ORE: 
# 
#   * Create an ore.frame containing text to analyze
#   * Build an ESA model and explore that model's metadata
#   * Score the input data to extract topics
#   * Load the pre-built WikiModel and explore it's metadata
#   * Score using predict() on the input data above with the WikiModel
#   * Score using predictTopN() on the input data above with the WikiModel

# Load the ORE library

library(ORE)

# Turn off row ordering warnings
options(ore.warn.order=FALSE)

# Create an ORE Connection
ore.connect(user        = "rquser",
            conn_string = "OAA1",
            host        = "localhost",
            password    = "rquser",
            all         = FALSE)  # this disables creating ore.frames for all schema tables/views
ore.attach()

rm(list = ls())  # housekeeping


###########################
# Create demo data
###########################

title <- c('Aids in Africa: Planning for a long war',
           'Mars rover maneuvers for rim shot',
           'Mars express confirms presence of water at Mars south pole',
           'NASA announces major Mars rover finding',
           'Drug access, Asia threat in focus at AIDS summit',
           'NASA Mars Odyssey THEMIS image: typical crater',
           'Road blocks for Aids')

#-- ORE supports both character and CLOB columns. Create an example of each.

# TEXT contents in character column
df <- data.frame(ID = seq(length(title)), TITLE = title)
ESA_TEXT <- ore.push(df)

# TEXT contains in clob column
attr(df$TITLE, "ora.type") <- "clob"
ESA_TEXT_CLOB <- ore.push(df)

#-- Create a text policy, which is required to build an ESA model

# the CTXSYS.CTX_DDL privilege is required
ore.exec("BEGIN ctx_ddl.drop_policy('ESA_TXTPOL'); END;")
ore.exec("BEGIN ctx_ddl.create_policy('ESA_TXTPOL'); END;")

###########################
# Build ESA model 1
###########################

#-- Build the ESA model specifying the TEXT POLICY_NAME, MIN_DOCUMENTS, 
#--   MAX_FEATURES and ESA algorithm settings in odm.settings

# Here, the CLOB version of the input data is used to build the model

esa.mod <- ore.odmESA(~., data = ESA_TEXT_CLOB,
                      odm.settings = list(case_id_column_name = "ID",
                                          ODMS_TEXT_POLICY_NAME = "ESA_TXTPOL",
                                          ODMS_TEXT_MIN_DOCUMENTS = 1,
                                          ODMS_TEXT_MAX_FEATURES = 5,
                                          ESAS_MIN_ITEMS = 1,
                                          ESAS_VALUE_THRESHOLD = 0.0001,
                                          ESAS_TOPN_FEATURES = 3))

class(esa.mod)    # view the class of the model - ore.odmESA
summary(esa.mod)  # view the model summary metadata
settings(esa.mod) # retrieve model settings explicitly
features(esa.mod) # retrieve model features (topics) explicitly

###########################
# Score input data
###########################

#-- Predict using the character version of the input data (could also use CLOB)

# type = "class" produces the top scoring feature 
# As we'd expect, each text entry predicts itself

predict(esa.mod, ESA_TEXT, type = "class", supplemental.cols = "ID")


###########################
# Build ESA model 2
###########################

# In contrast, use ctx.settings to specify a character column as TEXT and
# the same settings as above as well as TOKEN_TYPE, but use the character version of input data

esa.mod2 <- ore.odmESA(~., data = ESA_TEXT,
                       odm.settings = list(case_id_column_name = "ID", ESAS_MIN_ITEMS = 1),
                       ctx.settings = list(TITLE =
                                           "TEXT(POLICY_NAME:ESA_TXTPOL)(TOKEN_TYPE:STEM)(MIN_DOCUMENTS:1)(MAX_FEATURES:3)"))

summary(esa.mod2)  # view the model summary metadata (change from 5 to 3 max features)
settings(esa.mod2) # retrieve model settings explicitly
features(esa.mod2) # retrieve model features (topics) explicitly

###########################
# Score input data 2
###########################

#-- Predict using the CLOB version of the input data (could also use character data)
#--   Note the change in feature ID predicted

predict(esa.mod2, ESA_TEXT_CLOB, type = "class", supplemental.cols = "ID")


###########################
# Compare features
###########################

#-- Compares cross-product of text found in "compare.cols", add the ID to the output

names(ESA_TEXT_CLOB)
fc <- feature_compare(esa.mod2, ESA_TEXT_CLOB, compare.cols = "TITLE", supplemental.cols = "ID")
fc.local <- ore.pull(fc)
fc.local$ID_A <- as.factor(fc.local$ID_A)
fc.local$ID_B <- as.factor(fc.local$ID_B)

#-- Produce a heatmap of the similarity between "documents", i.e., the 7 text strings
#-- Notice that the diagonal entires are perfectly similar as expected, but 
#-- Rows 1, 5 and 7 are also very similar

library(ggplot2)
ggplot(fc.local, aes(ID_A, ID_B)) +
    geom_tile(aes(fill = SIMILARITY), colour = "white") +
    scale_fill_gradient(low = "white",high = "steelblue")

###########################
# Clean up
###########################

#-- policy no longer needed, so can drop

ore.exec("BEGIN ctx_ddl.drop_policy('ESA_TXTPOL'); END;")

###############################
# Working with the Wiki Model
###############################


#-- While creating your own domain-specific model may be necessary 
#--  in many situations, others may benefit from a pre-built model 
#--  based on millions of Wikipedia articles reduced to 200,000 topics.

#-- To enable using the prebuilt model in ORE, we've added a few functions
#--  not yet in the released product for your use. 

ore.createESA.wiki_model <- function () {
  model.name <- "WIKI_MODEL"
  attr(model.name, "owner") <- OREbase:::.ore.schema()
  formula <- "~ TEXT"
  formula <- as.formula(formula, env = parent.frame())
  env.lst <- list()
  model.settings   <- OREdm:::.ore.getModelSettings(model.name,"esas_")
  model.attributes <- OREdm:::.ore.getModelAttributes(model.name)
  query <- paste("SELECT ",
                 "FEATURE_ID, ",
                 "nvl2(attribute_subname, ", "attribute_name","||","'.'", "||",
                 "attribute_subname,  attribute_name) attribute_name,",
                 "COEFFICIENT ",
                 "FROM ", "DM$VAWIKI_MODEL",
                 " where ROWNUM <= 10 order by 1,2,3",
                 sep="");
  features.all <- OREdm:::.ore.frame4query(query, extRef = env.lst)
  esa.mod <- OREdm:::.create.ore.odmESA(model.name,
                                        model.settings,
                                        model.attributes,
                                        formula,
                                        env.lst,
                                        match.call(),
                                        features=features.all)
}

#-- Create the WikiModel proxy object 

WikiModel <- ore.createESA.wiki_model()

#-- Load two functions
#--   The first returns features as an ore.frame
#--   The second allows getting the top N extracted features

features.wiki_model <- function(object,...)
{
  model.owner <- OREdm:::.ore.modelOwner(object)
  query <- OREdm:::.genQryfeats(object$name, model.owner)
  OREdm:::.ore.frame4query(query, extRef = object$extRef)
}

predictTopN <- function (
  object,
  newdata,
  supplemental.cols = NULL,     # Columns to retain in the output
  na.action = na.pass,          # allow missing values in rows by default, or na.omit
  topN = NULL,
  ...)
{
  mf <- OREdm:::.ore.model.framepart(object, data = newdata, na.action = na.action,
                                     supplemental.cols = supplemental.cols)
  modelFullName  <- paste(OREdm:::.ore.modelOwner(object), object$name, sep=".")
  if (is.null(supplemental.cols))  slist_cols <- NULL
  else slist_cols <- paste(paste("\"", supplemental.cols, "\"", sep = "", collapse = ","), ",")
  sqlName  <- OREbase:::.ore.genName(mf@sqlName)
  sqlValue <- OREbase:::.ore.genValue(mf@sqlValue)
  sqlTable <- mf@dataQry
  qryName  <- OREbase:::.ore.qryName(sqlName)
  qryValue <- OREbase:::.ore.qryAlias(sqlValue,OREbase:::.ore.dQuote(mf@desc$name))
  qryTable <- OREbase:::.ore.qryTable(sqlTable)
  dataName <- sprintf("select %s %s from %s", qryName, qryValue, qryTable)
  fraObj <- OREbase:::.ore.obj()
  fraQry <- mf@dataQry
  if (!((is.numeric(topN) && as.integer(topN) == topN && topN > 0) || is.null(topN)))
    stop(gettextf("topN must be positive integer or null"))
  if (!is.null(topN))
  {
    predict.query.string <- paste(
      "SELECT ", qryName, " rnum, ", slist_cols,
      " S.FEATURE_ID feature, S.VALUE probability ",
      " FROM (SELECT ", qryName, slist_cols,
      " row_number() over (order by 1) rnum, FEATURE_SET (", modelFullName, ", ", topN,
      " using *) resset FROM (", dataName, ")) T, table(T.resset) S ",
      " order by rnum ", sep = "")
  }
  else
  {
    predict.query.string <- paste(
      "SELECT ", qryName, " rnum, ", slist_cols,
      " S.FEATURE_ID feature, S.VALUE probability ",
      " FROM (", " SELECT ", qryName, slist_cols,
      " row_number() over (order by 1) rnum, FEATURE_SET (",  modelFullName,
      " using *) resset FROM (", dataName, ")) T, table(T.resset) S ",
      " order by rnum ", sep = "")
  }
  fraQry[fraObj] <- OREbase:::.ore.paren(predict.query.string)
  desc <- OREbase:::.ore.desc(fraQry, sqlName = sqlName)
  sqlAlias <- OREbase:::.ore.dQuote(desc$name)
  sqlValue <- OREbase:::.ore.genValue(sqlAlias)
  fraObj   <- OREbase:::.ore.obj()
  fraQry   <- OREbase:::.ore.fraQuery(fraObj, sqlName, sqlAlias, fraQry)
  OREbase:::.ore.new("ore.frame", dataQry = fraQry, dataObj = fraObj, desc = desc,
                     sqlName = sqlName, sqlValue = sqlValue, sqlTable = fraQry, sqlPred = "",
                     extRef = c(object$extRef, mf@extRef))
}


#-- View model metadata

class(WikiModel)           # view the class of the model - ore.odmESA
summary(WikiModel)         # view the model summary metadata
settings(WikiModel)        # retrieve model settings explicitly

###########################
# Score input data
###########################

#-- Predict using type = "class" to produce top scoring feature

# The following **fails** because the prebuilt WikiModel expect the text column to be named "TEXT
predict(WikiModel, ESA_TEXT, type = "class", supplemental.cols = "TITLE")

# So let's change that here
ESA_TEXT2 <- ESA_TEXT
names(ESA_TEXT2) <- c("ID","TEXT")  # must rename TITLE column to match column when model was built

predictTopN(WikiModel, ESA_TEXT2, supplemental.cols = "TEXT",topN = 2L)


###########################
# Feature Comparison
###########################

#-- Compare individual topics / terms for similarity

text <- c('street', 'avenue')
df <- data.frame(ID = seq(length(text)), TEXT = text)
TEXT <- ore.push(df)
res <- feature_compare(WikiModel, TEXT, compare.cols = "TEXT", supplemental.cols = "ID")
res
res[res[[1]] < res[[2]],]  # exclude duplicate cross-product entries and matrix diagonal

res <- feature_compare(WikiModel, TEXT, compare.cols = "TEXT", supplemental.cols = "TEXT")
res
res[res[[1]] < res[[2]],]


text <- c('street', 'avenue', 'road')
df <- data.frame(ID = seq(length(text)), TEXT = text)
TEXT <- ore.push(df)
res <- feature_compare(WikiModel, TEXT, compare.cols = "TEXT", supplemental.cols = "ID")
res
res[res[[1]] < res[[2]],]

#-- Display heatmap of similarities among the three terms

fc.local <- ore.pull(res)
fc.local$ID_A <- factor(fc.local$ID_A,labels=text)
fc.local$ID_B <- factor(fc.local$ID_B,labels=text)

ggplot(fc.local, aes(ID_A, ID_B)) +
    geom_tile(aes(fill = SIMILARITY), colour = "white") +
    scale_fill_gradient(low = "white",high = "steelblue")

#-- Notice the lack of similarity between these terms

text <- c('street', 'farm')
df <- data.frame(ID = seq(length(text)), TEXT = text)
TEXT <- ore.push(df)
res <- feature_compare(WikiModel, TEXT, compare.cols = "TEXT", supplemental.cols = "ID")
res[res[[1]] < res[[2]],]

#######################################
# Feature Comparison using longer text
#######################################

text <- c("The Securities and Exchange Commission sued Tesla's CEO on Thursday for making 'false and misleading'
   statements to investors. It's asking a federal judge to prevent Musk from serving as an officer or a director 
   of a public company, among other penalties. The complaint hinges on a tweet Musk sent on August 7 about taking Tesla private.
   'Am considering taking Tesla private at $420,' Musk said. 'Funding secured.'
   The SEC said he had not actually secured the funding.
   'In truth and in fact, Musk had not even discussed, much less confirmed, key deal terms, including price, with any 
   potential funding source,' the SEC said in its complaint.
   That tweet, and subsequent tweets from Musk over the next three hours, caused 'significant confusion and disruption 
   in the market for Tesla's stock,' as well as harm to investors, the SEC said. On the day of Musk's tweet, Tesla's 
   stock shot up nearly 9%. It has declined substantially since then.",

   "The Securities and Exchange Commission filed a lawsuit Thursday against Elon Musk, the chief executive of 
   Tesla, accusing him of making false public statements with the potential to hurt investors.
   The lawsuit, filed in federal court in New York, seeks to bar Mr. Musk from serving as an executive 
   or director of publicly traded companies. Tesla, the electric-car maker of which Mr. Musk was a co-founder, 
   is publicly traded. The suit relates to an Aug. 7 Twitter post by Mr. Musk, in which he said he had 'funding secured' 
   to convert Tesla into a private company. The S.E.C. said Mr. Musk 'knew or was reckless in not knowing' that his 
   statements were false or misleading. 'In truth and in fact, Musk had not even discussed, much less confirmed, 
   key deal terms, including price, with any potential funding source,' the S.E.C. said in its lawsuit.")

df <- data.frame(ID = seq(length(text)), TEXT = text)
TEXT <- ore.push(df)
res <- feature_compare(WikiModel, TEXT, compare.cols = "TEXT", supplemental.cols = "ID")
res[res[[1]] < res[[2]],]

text <- c("The Securities and Exchange Commission sued Tesla's CEO on Thursday for making 'false and misleading'
   statements to investors. It's asking a federal judge to prevent Musk from serving as an officer or a director 
   of a public company, among other penalties. The complaint hinges on a tweet Musk sent on August 7 about taking Tesla private.
   'Am considering taking Tesla private at $420,' Musk said. 'Funding secured.'
   The SEC said he had not actually secured the funding.
   'In truth and in fact, Musk had not even discussed, much less confirmed, key deal terms, including price, with any 
   potential funding source,' the SEC said in its complaint.
   That tweet, and subsequent tweets from Musk over the next three hours, caused 'significant confusion and disruption 
   in the market for Tesla's stock,' as well as harm to investors, the SEC said. On the day of Musk's tweet, Tesla's 
   stock shot up nearly 9%. It has declined substantially since then.",

   "If humans had lived 200 million years ago, they would have marveled at the largest dinosaur of its time. 
   It's name means 'a giant thunderclap at dawn.' The recently discovered fossil of a new dinosaur species in 
   South Africa revealed a relative of the brontosaurus that weighed 26,000 pounds, about double the size of 
   a large African elephant. The researchers have named it Ledumahadi mafube, which is Sesotho for 'a giant 
   thunderclap at dawn.' Sesotho is an official South African language indigenous to the part of the country 
   where the dinosaur was found. 'The name reflects the great size of the animal as well as the fact that its 
   lineage appeared at the origins of sauropod dinosaurs,' said Jonah Choiniere, study author and paleontology 
   professor at the University of the Witwatersrand in Johannesburg, South Africa. 'It honors both the recent 
   and ancient heritage of southern Africa.")

df <- data.frame(ID = seq(length(text)), TEXT = text)
TEXT <- ore.push(df)
res <- feature_compare(WikiModel, TEXT, compare.cols = "TEXT", supplemental.cols = "ID")
res[res[[1]] < res[[2]],]

###############################################
# Explore the 2018 State of the Union text
###############################################

#-- In this scenario we look at the State of the Union text, treating each paragraph
#-- as a separate document. The goal is to see what themes are expressed in each 
#-- paragraph and how similar each paragraph is in theme

#-- SOTU 2009 and 2018 are also avaialable. To choose, modify the text filename below

#-- Load data from text file

setwd("~/ORE")
dat <- scan("SOTU-2017.txt", what=character(), sep="\n")
head(dat,3)

#-- TEXT contents in character column

df <- data.frame(ID = seq(length(dat)), TEXT = dat)
ESA_TEXT <- ore.push(df)
dim(ESA_TEXT)

#-- Predict the top 3 topics per paragraph

pred <- predictTopN(WikiModel, ESA_TEXT, topN=3, supp = "ID")[,2:4]
head(pred,20)


#-- feature compare

fc <- feature_compare(WikiModel, ESA_TEXT, compare.cols = "TEXT", supplemental.cols = "ID")
class(fc)

fc.local <- ore.pull(fc) # Pull the comparison result to plot a heatmap below
fc.local$ID_A <- as.factor(fc.local$ID_A)
fc.local$ID_B <- as.factor(fc.local$ID_B)
dim(fc.local)

# View the headmap for similarlity across all paragraphs

ggplot(fc.local, aes(ID_A, ID_B)) +
    geom_tile(aes(fill = SIMILARITY), colour = "white") +
    scale_fill_gradient(low = "white",high = "steelblue")

library(OREdplyr)
library(dplyr)
library(magrittr)

# Focus in on blocks that show multiple paragraphs spent on related or the same topics

# r1 <- 20:30 # 2018
 r1 <- 32:38 # 2017
# r1 <- 53:59 # 2009

fc.local2 <- fc.local %>% filter(ID_A %in% r1, ID_B %in% r1)
ggplot(fc.local2, aes(ID_A, ID_B)) +
    geom_tile(aes(fill = SIMILARITY), colour = "white") +
    scale_fill_gradient(low = "white",high = "steelblue")

ESA_TEXT %>% filter(ID %in% r1)
pred %>% filter(ID %in% r1)


# Focus in on a second block

# r2 <- 84:90   # 2018
 r2 <- 42:46 # 2017
# r2 <- 44:50 # 2009

fc.local3 <- fc.local %>% filter(ID_A %in% r2, ID_B %in% r2)
ggplot(fc.local3, aes(ID_A, ID_B)) +
    geom_tile(aes(fill = SIMILARITY), colour = "white") +
    scale_fill_gradient(low = "white",high = "steelblue")

ESA_TEXT %>% filter(ID %in% r2)
pred %>% filter(ID %in% r2)

#-- Produce a bar plot of topics that appear with a frequency > 1

rr <- as.data.frame(table(pred$FEATURE))
names(rr) <- c("FEATURE","Freq")
dim(rr)
head(rr)
ggplot(rr[rr$Freq>1,], aes(reorder(FEATURE, Freq), Freq)) + geom_bar(stat="identity", fill="steelblue") +
  coord_flip() + xlab("Extracted Feature") + ylab("Count") +
  ggtitle("Top occurring extracted features from SOTU using WikiModel")

# Housekeeping

rm(list = ls())  

ore.disconnect()


################################################
## End of Script
################################################


