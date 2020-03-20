--##################################################################
--##
--## Oracle Machine Learning for R Vignette 
--## 
--## Variable Selection
--##
--## Copyright (c) 2020 Oracle Corporation                          
--##
--## The Universal Permissive License (UPL), Version 1.0
--## 
--## https://oss.oracle.com/licenses/upl/
--##
--###################################################################

select * 
from table(rqEval(cursor(select 1 "ore.connect",'HOUSE2' "tablename", 'HOUSE_var_ranking2' "dsname" from dual),
                  'select cast(''a'' as varchar2(24)) var, 1 importance, 1 rank from dual',
                  'HOUSE_var_ranking'));

  
--#-- End of Script