-- Example of double-indexing a column in order to use NDATA and "plain text" searching

-- Prepare the table and data 

Prompt Expect error here first time:
drop table namedata;

create table namedata (nametext varchar2(2000));

insert into namedata values ('William Smith');
insert into namedata values ('Smith, William');
insert into namedata values ('Will Smithe');
insert into namedata values ('William Smythe');

Prompt Expect errors here first time:
exec ctx_ddl.drop_preference('myds')
exec ctx_ddl.drop_section_group('mysections')

-- Multi_Column_Datastore will duplicate the names into two sections, so for example
--  we might get
--  <name>William Clinton</name> <ndname>William Clinton</ndname>

exec ctx_ddl.create_preference('myds', 'multi_column_datastore')
exec ctx_ddl.set_attribute('myds', 'columns', 'nametext as name, nametext as ndname')

-- Create section groups to index names as both ndata and normal

exec ctx_ddl.create_section_group('mysections', 'basic_section_group')
exec ctx_ddl.add_ndata_section('mysections', 'ndname', 'ndname')

-- this next one is optional, only needed if you need to do "xxx within name"
--- exec ctx_ddl.add_field_section('mysections', 'name', 'name', TRUE)

-- create the index

create index namedata_index on namedata(nametext) indextype is ctxsys.context
parameters ('datastore myds section group mysections');

column nametext format a40

-- simple non-ndata search
select score(1),nametext from namedata where contains (nametext, 'william smith',1) > 0 order by score(1) desc;

-- simple ndata search
select score(1),nametext from namedata where contains (nametext, 'ndata(ndname, william smith)',1) > 0 order by score(1) desc;


-- progressive relaxation query which does
--  seq1:  exact phrase match
--  seq2:  exact AND match 
--  seq3:  ndata search

-- if we get enough matches in seq1 we need go no further
-- note that anything that satisfied seq1 will not be returned by later sequences

select * from (
  select /* FIRST_ROWS(10) */ score(1), nametext from namedata where contains (nametext, '
  <query>
    <textquery>
      <progression>
        <seq>
          william smith
        </seq>
        <seq>
          william AND smith
        </seq>
        <seq>
          ndata(ndname, william smith)
        </seq>
      </progression>
    </textquery>
  </query>
  ', 1) > 0 order by score(1) desc
) where rownum <= 10;
 
