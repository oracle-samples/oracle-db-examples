--
--
-- Scan tables to look for column values that correlate
--    Only 2-column combinations are checked
--    Correlation is set to 80% - an arbitary figure
--    Data types limited
--    Only columns with shorter strings compared 
--    Columns checked must have a 'similar' number of distinct values (NDVs must not differ by 2X)
--    A sample of rows can be used to speed up execution time - which can be substantial
--
-- Parameters:
--    Sample percentage
--     Y/N where Y - will create the column groups immediately
--               N - will print the column group creation script only
--
  --
  -- The cursor C1 includes some predicates I've commented out
  -- If uncommented, they will reduce the number of columns comapared, but this
  -- risks missing some correlated columns. I chose to leave these ideas
  -- visible, but I think the best way to speed things up
  -- is to reduce the row sample percentage.
  --
var create_now varchar2(1)
set echo off
column tab_owner format a20
column tab_name format a20
set linesize 250
set trims on
set pagesize 10000
set feedback off

var tabname varchar2(100)
var ownname varchar2(100)
var samp number

exec select '&1' into :samp from dual;
exec select decode(nvl(upper('&2'),'N'),'N','N','Y') into :create_now from dual;

set serveroutput on

--
-- Look for column value correlation
--
declare
  --
  -- Columns must correlate >0.8 to get a column group (this value is chosen arbitrarily and can be adjusted) 
  --
  minimum_correlation number(6,5) := 0.8;

  cname1 varchar2(200);
  cname2 varchar2(200);

  cursor tabsc is
    select distinct object_name,object_owner
    from   plan_table
    where  object_type = 'TABLE'
    and    timestamp = (select max(timestamp) from plan_table)
    order by object_name;

  cursor extc is
    select count(*)
    from   dba_stat_extensions
    where  table_name = :tabname
    and    owner      = :ownname
    and    extension like '%'||cname1||'%'
    and    extension like '%'||cname2||'%';

  cursor ext is
    select extension_name,extension,rownum r
    from   dba_stat_extensions
    where  table_name = :tabname
    and    owner      = :ownname;
  --
  -- To reduce the number of column combinations checked, we will only check
  -- column pairs that have similar NDV - so some NULL cases will be missed.
  -- There is also an assumption that longer strings are rarely used in comparison
  --
  cursor c1 is
    with w as (
    select column_name, num_distinct
    from   dba_tab_columns
    where  table_name = :tabname
    and    owner      = :ownname
    and    num_distinct is not null
    and    num_distinct > 0
    and    (   data_type in ('DATE','NUMBER')
            or (data_type = 'CHAR' and data_length <= 20)
            or (data_type = 'VARCHAR2' and data_length <= 20)
            or (data_type like 'TIMESTAMP%')))
    select t1.column_name c1, t2.column_name c2
    from   w t1, w t2 /* , (select num_rows from dba_tables where owner = :ownname and table_name = :tabname) t */
    where  t1.column_name > t2.column_name
    --and    greatest(t1.num_distinct,t2.num_distinct)/least(t1.num_distinct,t2.num_distinct)<2 /* Similar number of distinct values? */
    --and    t1.num_distinct < t.num_rows/10   /* Perhaps eliminate sequenced columns? */
    order by t1.column_name;
  c number(6,5);
  n number;
  num_ext number;
  r clob;
begin
  if :samp>=100
  then
     :samp := 99.9999;
  end if;
  dbms_output.put_line('column es format a100');
 
  for tabs in tabsc
  loop
     :tabname := tabs.object_name;
     :ownname := tabs.object_owner;
  
     dbms_output.put_line('-- ');
     dbms_output.put_line('-- ******* '||:tabname||' *******');
     execute immediate 'select /*+ FULL */ count(*) from "'||:ownname||'"."'||:tabname||'" sample('||:samp||') ' into n;
     dbms_output.put_line('-- ');
     dbms_output.put_line('-- Row sample size (approx): '||n);
     dbms_output.put_line('-- ');
     dbms_output.put_line(' ');
     for x in ext
     loop
       dbms_output.put_line('-- Existing extension '||x.extension||'  '||x.extension_name);
     end loop;
     dbms_output.put_line(' ');

     for x in c1
     loop
        execute immediate 'select corr(ora_hash("'||x.c1||'"),ora_hash("'||x.c2||'")) from "'||:ownname||'"."'||:tabname||'" sample('||:samp||')' into c;
        if (c is not null and c > minimum_correlation)
        then
           dbms_output.put('-- '||x.c1 || ',' || x.c2 ||': good correlation = '||c);
           cname1 := x.c1;
           cname2 := x.c2;
           open extc;
           fetch extc into num_ext;
           close extc;
           if (num_ext>0)
           then
              dbms_output.put_line(' SKIPPING (covered already)');
           else
              dbms_output.put_line(' ');
              if :create_now = 'Y'
              then
                 select  dbms_stats.create_extended_stats(:ownname,:tabname,'("'||x.c1||'","'||x.c2||'")') into r from dual;
                 dbms_output.put_line('Extension created: ' || r);
              else
                 dbms_output.put_line('select dbms_stats.create_extended_stats(''"'||:ownname||'"'',''"'||:tabname||'"'',''("'||x.c1||'","'||x.c2||'")'') es from dual;');
              end if;
           end if;
        else
           if c is not null
           then
              dbms_output.put_line('-- '||x.c1 || ',' || x.c2 ||': poor correlation = '||c);
           else
              dbms_output.put_line('-- '||x.c1 || ',' || x.c2 ||': NULL correlation');
           end if; 
        end if;
     end loop;
   end loop;
end;
/

set serveroutput off
