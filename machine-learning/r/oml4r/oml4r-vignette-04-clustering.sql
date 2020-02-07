--##################################################################
--##
--## Oracle Machine Learning for R Vignette 
--## 
--## Clustering
--##
--## (c) 2020 Oracle Corporation
--##
--###################################################################

select * 
from table(rqEval(cursor(select 1 "ore.connect" from dual),
                  'PNG',
                  'Clustering_AUTO'));

  
--#-- End of Script