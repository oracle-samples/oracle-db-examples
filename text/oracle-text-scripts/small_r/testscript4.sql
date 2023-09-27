set define off

connect / as sysdba

set echo on

drop user newsys cascade;

create user newsys identified by newsys default tablespace system temporary tablespace temp quota unlimited on system;

grant connect,resource,ctxapp to newsys;

-- @small_r_conversion

connect newsys/newsys

set define off

set echo on

--drop table docs;
-- set echo off
set feedback off
select to_char( sysdate, 'HH:MI:SS') from dual;
--@randomtext
@imp newsys

delete from newsys.docs where id > 69999;

set define off

select to_char( sysdate, 'HH:MI:SS') from dual;

set feedback on

-- small r row version of the index if line not commented out

alter session set events '30579 trace name context forever, level 268435456';

connect newsys/newsys
set echo on

set define off

-- exec ctx_ddl.drop_preference('mystor')
exec ctx_ddl.create_preference('mystor','BASIC_STORAGE')
-- exec ctx_ddl.set_attribute('mystor', 'SMALL_R_ROW', 't')

create index docs$index on docs(text)
indextype is ctxsys.context
-- parameters('storage mystor')
/

select length(data) from dr$docs$index$r
/

set serverout on

exec ctxsys.small_r_convert.convert_index('newsys', 'docs$index')

select length(data) from dr$docs$index$r
/

select text from docs where contains (text, 'bababa and gigebeg') > 0;

select text from docs where contains(text, 'BOC FAG GACOF DICECE CEGACIC') > 0;

select text from docs where id = 69999;
