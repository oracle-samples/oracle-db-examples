connect / as sysdba

@drop

declare
   v_sql CLOB;
begin
   select sql_fulltext 
   into v_sql 
   from   v$sqlarea 
   where  sql_id='bdrzvmxvcju4y';

   sys.dbms_sqldiag_internal.i_create_patch(
      sql_text  =>v_sql,
      hint_text =>'IGNORE_OPTIM_EMBEDDED_HINTS', 
      name      =>'q1_patch');
end;
/

connect adhoc/adhoc
