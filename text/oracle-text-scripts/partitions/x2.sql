select idx_name as tab, ixp_name as part, idx_option as IDXOPT, ixp_option as PARTOPT from
ctxsys.dr$index,
ctxsys.dr$index_partition,
sys.user$
where user# = idx_owner#
and   idx_id = ixp_idx_id
and   name = 'ROGER'
and   idx_name = 'BIKE_ITEM_IDX'
/
