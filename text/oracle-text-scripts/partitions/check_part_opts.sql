column tab format a25
column part format a25
column idxopt format a8
column partopt format a8

select idx_name as tab, 
       ixp_name as part, 
       idx_option as IDXOPT, 
       ixp_option as PARTOPT 
from
       ctxsys.dr$index,
       ctxsys.dr$index_partition,
       sys.user$
where  
       user#    = idx_owner#
and    idx_id   = ixp_idx_id
and    name     = upper('ROGER')
and    idx_name = upper('BIKE_ITEMS_IDX')
/
