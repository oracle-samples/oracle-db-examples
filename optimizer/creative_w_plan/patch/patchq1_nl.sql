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
      hint_text =>'LEADING(@"SEL$5DA710D3" "TAB2"@"SEL$2" "TAB1"@"SEL$1") USE_NL(@"SEL$5DA710D3" "TAB1"@"SEL$1")', 
      name      =>'q1_patch');
end;
/

connect adhoc/adhoc
