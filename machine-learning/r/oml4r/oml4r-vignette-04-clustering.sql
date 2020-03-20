--##################################################################
--##
--## Oracle Machine Learning for R Vignette 
--## 
--## Clustering
--##
--## Copyright (c) 2020 Oracle Corporation                          
--##
--## The Universal Permissive License (UPL), Version 1.0
--## 
--## https://oss.oracle.com/licenses/upl/
--##
--###################################################################
select * 
from table(rqEval(cursor(select 1 "ore.connect" from dual),
                  'PNG',
                  'Clustering_AUTO'));

  
--#-- End of Script