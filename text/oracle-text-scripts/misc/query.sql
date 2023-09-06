select distinct cont_FName, cont_LName, cont_jobtitle, email_address, email_primary_flg, u.row_id
from ext_contacts c, emails e, ext_users u, parties_relations r
where 
r.relationship_type = 'USER_CONTACTS'  and c.cont_active_flg = 'Y' and
    e.party_id = c.row_id and c.application_code = 'SC' and r.party_id_from = '50008' and
    contains(cont_FName, 'john and alan and crm')>0


