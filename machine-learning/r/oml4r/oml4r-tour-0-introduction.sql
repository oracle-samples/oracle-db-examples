--###########################################################################
--##
--## Oracle Machine Learning for R
--##
--## Demo Script for OML4R Tour
--##
--## Copyright (c) 2020 Oracle Corporation
--##
--## The Universal Permissive License (UPL), Version 1.0
--## 
--## https://oss.oracle.com/licenses/upl/
--##
--###########################################################################

--# OML4R Tour

-- Random Red Dots
-- Generate images of random red dots and a simple data.frame
begin
  sys.rqScriptDrop('RandomRedDots2');
  sys.rqScriptCreate('RandomRedDots2',
 'function(num_dots_1=100, num_dots_2=10){
            id <- 1:10
            plot( 1:num_dots_1, rnorm(num_dots_1), pch = 21, 
                  bg = "red", cex = 2, main="Random Red Dots" )
            plot( 1:num_dots_2, rnorm(num_dots_2), pch = 21, 
                  bg = "red", cex = 2, main="Random Red Dots" )
            data.frame(id=id, val=id / 100)
            }');
end;
/

-- Return image only as PNG BLOB, one per image per row
-- Structured content not returned with PNG option
select    ID, IMAGE
from      table(rqEval( NULL,'PNG','RandomRedDots2'));

-- Return structured data only by specifying table definition
select    id, val
from      table(rqEval( NULL,'select 1 id, 1 val from dual','RandomRedDots2'));

-- Return structured and image content within XML string
select    dbms_lob.substr( value, 4000, 1 ) 
from      table(rqEval(NULL, 'XML', 'RandomRedDots2'));

-- Pass arguments to change number of dots
select    ID, IMAGE
from      table(rqEval(cursor(select 500 "num_dots_1", 800 "num_dots_2" from dual),
                       'PNG', 'RandomRedDots2'));
  
--#####################################################
--##  End of Script
--#####################################################

