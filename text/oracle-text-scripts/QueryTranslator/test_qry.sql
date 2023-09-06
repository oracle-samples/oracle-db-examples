-- allow output from dbms_output.put_line from PL/SQL -- and System.out.println() from Java 
set serveroutput on 
call dbms_java.set_output(2000); 
column text format a60 
variable srch varchar2(2000);
set pagesize 60
-- Note we'll put the search string into a bind variable first, then use 
-- that bind variable in the query. Using the function directly in the query 
-- will prevent the query optimiser from accessing the query string
-- How a bind variable is used will depend on your programming language - we 
-- are using a SQL*Plus variable here. 

variable srch varchar2(2000)
set echo on

exec :srch := rep.OTSearchString('+cat dog rabbit fox -fish') 
print srch
select score(0), text from avtest where contains (text, :srch, 0)>0 order by score(0) desc; 	

exec :srch := rep.OTProgRelaxClob('+cat +dog rabbit fox -fish', 'avtestindex')
print srch
select score(0), text from avtest where contains (text, :srch, 0)>0 order by score(0) desc; 	

exec :srch := rep.OTProgRelaxClob('+cat +dog rabbit -fish', 'avtestindex')
print srch
select score(0), text from avtest where contains (text, :srch, 0)>0 order by score(0) desc; 	

exec :srch := rep.OTProgRelaxClob('+cat +dog rabbit', 'avtestindex')
print srch
select score(0), text from avtest where contains (text, :srch, 0)>0 order by score(0) desc; 	

exec :srch := rep.OTProgRelaxClob('cat dog rabbit', 'avtestindex')
print srch
select score(0), text from avtest where contains (text, :srch, 0)>0 order by score(0) desc; 	

exec :srch := rep.OTProgRelaxClob('cat volkswagen dog rabbit', 'avtestindex')
print srch
select score(0), text from avtest where contains (text, :srch, 0)>0 order by score(0) desc; 	

exec :srch := rep.OTProgRelaxClob('cat +dog', 'avtestindex')
print srch
select score(0), text from avtest where contains (text, :srch, 0)>0 order by score(0) desc; 	

exec :srch := rep.OTProgRelaxClob('cat +nt', 'avtestindex')
print srch
select score(0), text from avtest where contains (text, :srch, 0)>0 order by score(0) desc; 	

exec :srch := rep.OTProgRelaxClob('+"cat nt" rabbit', 'avtestindex')
print srch
select score(0), text from avtest where contains (text, :srch, 0)>0 order by score(0) desc; 	

exec :srch := rep.OTProgRelaxClob('cat +nt dog', 'avtestindex')
print srch
select score(0), text from avtest where contains (text, :srch, 0)>0 order by score(0) desc; 	

exec :srch := rep.OTProgRelaxClob('"dog cat"', 'avtestindex')
print srch
select score(0), text from avtest where contains (text, :srch, 0)>0 order by score(0) desc; 	

exec :srch := rep.OTProgRelaxClob('+"dog cat"', 'avtestindex')
print srch
select score(0), text from avtest where contains (text, :srch, 0)>0 order by score(0) desc; 	

exec :srch := rep.OTProgRelaxClob('"cat dog rabbit"', 'avtestindex')
print srch
select score(0), text from avtest where contains (text, :srch, 0)>0 order by score(0) desc; 	

exec :srch := rep.OTProgRelaxClob('rabbit +"dog cat"', 'avtestindex')
print srch
select score(0), text from avtest where contains (text, :srch, 0)>0 order by score(0) desc; 	

exec :srch := rep.OTProgRelaxClob('cat-dog', 'avtestindex')
print srch
select score(0), text from avtest where contains (text, :srch, 0)>0 order by score(0) desc; 	

exec :srch := rep.OTProgRelaxClob('cat.*dog', 'avtestindex')
print srch
select score(0), text from avtest where contains (text, :srch, 0)>0 order by score(0) desc; 	

exec :srch := rep.OTProgRelaxClob('cat[]dog', 'avtestindex')
print srch
select score(0), text from avtest where contains (text, :srch, 0)>0 order by score(0) desc; 	

exec :srch := rep.OTProgRelaxClob('cat-dog -fish', 'avtestindex')
print srch
select score(0), text from avtest where contains (text, :srch, 0)>0 order by score(0) desc; 	


exec :srch := rep.OTProgRelaxClob('*****************', 'avtestindex')
print srch
select score(0), text from avtest where contains (text, :srch, 0)>0 order by score(0) desc; 	

set echo off

-- drop table qlog;
-- create table qlog (t varchar2(4000));
-- 
-- create or replace procedure go (str varchar2, join varchar2 default null) is
--   q varchar2(4000);
-- begin
--   q := rep.OTProgRelaxClob(str, join);
--   if (q) is null then
--     dbms_output.put_line ('Null query');
--   elsif length(q) = 0 then
--     dbms_output.put_line ('Empty string query');
--   else
--     delete from qlog;
--     insert into qlog values (q);
--     if length(q) > 0 then
--       for c in (select score(0) scr, text from avtest where contains (text, q, 0) > 0 order by score(0) desc) loop
--         dbms_output.put_line (rpad (c.scr, 6)|| c.text);
--       end loop;
--     end if;
--   end if;
-- end;
-- /
-- 
-- create or replace procedure go2 (str varchar2, join varchar2 default null) is
--   q varchar2(4000);
-- begin
--   q := rep.OTSearchString(str, join);
--   if (q) is null then
--     dbms_output.put_line ('Null query');
--   elsif length(q) = 0 then
--     dbms_output.put_line ('Empty string query');
--   else
--     dbms_output.put_line('query is '||q);
--     delete from qlog;
--     insert into qlog values (q);
--     if length(q) > 0 then
--       for c in (select score(0) scr, text from avtest where contains (text, q, 0) > 0 order by score(0) desc) loop
--         dbms_output.put_line (rpad (c.scr, 6)|| c.text);
--       end loop;
--     end if;
--   end if;
-- end;
-- /

