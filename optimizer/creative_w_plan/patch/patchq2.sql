connect / as sysdba
set serveroutput on

@drop

declare
  hint varchar2(1024) := '';
  v_sql CLOB;
  cursor c1 is
   SELECT  extractValue(value(h),'.') AS hint
   FROM    v$sql_plan sp,
        TABLE(xmlsequence(
            extract(xmltype(sp.other_xml),'/*/outline_data/hint'))) h
   WHERE   sp.other_xml is not null
   AND     child_number = 0
   AND     sql_id = 'bshak75293cfs';
begin
  for c in c1
  loop
     hint := hint || ' ' ||c.hint;
  end loop;

  dbms_output.put_line('OUTLINE> '||hint);

  select sql_fulltext 
   into v_sql 
   from   v$sqlarea 
   where  sql_id='afbaqn1zcxs7c';

   sys.dbms_sqldiag_internal.i_create_patch(
      sql_text  =>v_sql,
      hint_text =>hint, 
      name      =>'q2_patch');
end;
/

connect adhoc/adhoc
