@drop

connect / as sysdba

declare
  hints varchar2(1024) := '';
  v_sql CLOB;
  cursor c1 is
   SELECT  extractValue(value(h),'.') AS hint
   FROM    v$sql_plan sp,
        TABLE(xmlsequence(
            extract(xmltype(sp.other_xml),'/*/outline_data/hint'))) h
   WHERE   sp.other_xml is not null
   AND     sql_id = 'bshak75293cfs'   /* Take outline from this SQL */
   AND     child_number = 0;
 begin
  for c in c1
  loop
     hints := hints || ' ' ||c.hint;
  end loop;
  select  sql_fulltext 
   into   v_sql 
   from   v$sqlarea 
   where  sql_id='afbaqn1zcxs7c';    /* Apply to this SQL */

  sys.dbms_sqldiag_internal.i_create_patch(
      sql_text  =>v_sql,
      hint_text =>hints, 
      name      =>'q2_patch');
end;
/

connect adhoc/adhoc
