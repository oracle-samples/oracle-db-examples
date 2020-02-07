################################################
##
## Oracle Machine Learning for R Vignette
##
## Extensibility for R Models
##
## (c) 2020 Oracle Corporation
##
################################################

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

#-- Create a temporary ORE frame

IRIS <- ore.push(iris)

#-- Create the build function for R's GLM algorithm
#--   Note with overwrite=TRUE, no need to drop the script first

ore.scriptDrop("glm_build", global=TRUE)
ore.scriptCreate("glm_build", function(data, form, family) 
  glm(formula = form, data = data, family = family), global=TRUE, overwrite=TRUE)

#-- Create the score function for the model created above

ore.scriptDrop("glm_score", global=TRUE)
ore.scriptCreate("glm_score", function(mod, data) {
  res <- predict(mod, newdata = data); data.frame(res)}, global=TRUE, overwrite=TRUE)

#-- Create the model details function for the model created above

ore.scriptDrop("glm_detail", global=TRUE)
ore.scriptCreate("glm_detail", function(mod) 
  data.frame(name=names(mod$coefficients), coef=mod$coefficients), global=TRUE, overwrite=TRUE)

#-- Build the model and associate the score and detail functions

ralg.mod <- ore.odmRAlg(IRIS, mining.function = "regression",
                        formula = c(form="Sepal.Length ~ ."),
                        build.function  = "glm_build", build.parameter = list(family="gaussian"),
                        score.function  = "glm_score",
                        detail.function = "glm_detail", detail.value = data.frame(name="a", coef=1))

#-- The summary() function provides the call, settings, and coefficients for the model

summary(ralg.mod)

#-- Access model components, such as details that were returned from the glm_detail function
ralg.mod$details

#-- Use this model to predict Sepal Length

predict(ralg.mod, newdata = head(IRIS), supplemental.cols = "Sepal.Length")

# housekeeping

rm(list=ls())
ore.disconnect()


################################################
## End of Script
################################################


