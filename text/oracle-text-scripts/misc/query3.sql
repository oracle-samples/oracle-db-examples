select cont_FName
from table1 c, table2 r
where 
    r.party_id_from = '50008'
    and contains(cont_FName, 'john and alan and crm')>0;
