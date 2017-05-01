connect / as sysdba

@drop

declare
   v_sql CLOB;
begin
   select sql_fulltext 
   into   v_sql 
   from   v$sqlarea 
   where  sql_id='37090abayamah';

   sys.dbms_sqldiag_internal.i_create_patch(
      sql_text  =>v_sql,
      hint_text =>'FULL(@"SEL$1" "TAB1"@"SEL$1")', 
      name      =>'q0_patch');
end;
/

connect adhoc/adhoc
