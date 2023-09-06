select cont_FName
from ext_contacts c, parties_relations r
where 
    r.party_id_from = '50008'
    and contains(cont_FName, 'john and alan and crm')>0;
