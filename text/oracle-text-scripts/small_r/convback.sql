connect fusion/fusion

alter table DR$EGP_ITEM_TEXT_TL_CTX1$R rename to DR$EGP_ITEM_TEXT_TL_CTX1$RX;
alter table DR$EGP_ITEM_TEXT_TL_CTX1$RX drop constraint DRC$EGP_ITEM_TEXT_TL_CTX1$R;
alter table DR$EGP_ITEM_TEXT_TL_CTX1$RO rename to DR$EGP_ITEM_TEXT_TL_CTX1$R;
alter table DR$EGP_ITEM_TEXT_TL_CTX1$R add constraint DRC$EGP_ITEM_TEXT_TL_CTX1$R primary key (row_no);

connect / as sysdba
xs
update ctxsys.dr$index_value 
set ixv_value = 0 
where (ixv_idx_id, ixv_oat_id) = (
  select 
    idx_id, 
    oat_id
 from 
   ctxsys.dr$object_attribute,
   ctxsys.dr$index,
   ctxsys.dr$object,
   ctxsys.dr$class,
   sys.all_users u
 where 
       idx_owner# = u.user_id 
   and idx_name   = 'EGP_ITEM_TEXT_TL_CTX1'
   and oat_name   = 'SMALL_R_ROW'
   and oat_cla_id = obj_cla_id
   and oat_obj_id = obj_id
   and cla_system = 'N'
   and oat_cla_id = cla_id
   and u.username = 'FUSION')
/

alter system flush shared_pool;
