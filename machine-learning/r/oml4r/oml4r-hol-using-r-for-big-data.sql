--##################################################################
--##
--## Using R for Big Data Advanced Analytics and Machine Learning 
--## 
--## Hands-On Lab
--##
--## (c) 2020 Oracle Corporation
--##
--###################################################################

-- Connect to rquser schema to execute

select 1 A, 2 B from dual; -- Example: returns one row with values and column names specified 

select 1 "ore.connect",'CYL_NB_MODEL_1' "dsname" from dual; -- used below

-- Score data from AUTO using Naive Bayes model created from R

select    * 
from      table(rqRowEval( cursor(select "mpg","cylinders","displacement","horsepower","weight",
                                    "acceleration","year","origin" from RQUSER2.AUTO),
                           cursor(select 1 "ore.connect",'CYL_NB_MODEL_1' "dsname" from dual),
                           'select 1 mpg, ''a'' cylinders, 1 displacement, 1 horsepower, 1 weight, 1 acceleration, ''aa'' year, ''a'' origin, ''a'' PRED from dual',
                           10,
                           'scoreNBmodel2'));


-- Random Red Dots
-- Generate an image of random red dots and a simple data.frame result

begin
  --sys.rqScriptDrop('RandomRedDots');  -- uncomment this line if script fails
  sys.rqScriptCreate('RandomRedDots',
 'function(){
            id <- 1:10
            plot( 1:100, rnorm(100), pch = 21, 
                  bg = "red", cex = 2, main="Random Red Dots" )
            data.frame(id=id, val=id / 100)
            }');
end;
/

-- Return image ony as PNG BLOB, one per image per row
-- Structured content not returned with PNG option

select    ID, IMAGE
from      table(rqEval( NULL,'PNG','RandomRedDots'));


-- Return structured data only by specifying table definition

select    * 
from      table(rqEval( NULL,'select 1 id, 1 val from dual','RandomRedDots'));


-- Return structured and image content within XML string

select    *
from      table(rqEval(NULL, 'XML', 'RandomRedDots'));


-- Go back to R and invoke

-- ore.doEval(FUN.NAME='RandomRedDots')
 


--###########################################
--## End of Script
--###########################################

 