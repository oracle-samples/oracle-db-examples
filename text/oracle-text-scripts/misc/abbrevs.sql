set echo on
set define off

drop table xres
/
create table xres (
      explain_id      varchar2(30),
      id              number,
      parent_id       number,
      operation       varchar2(30),
      options         varchar2(30),
      object_name     varchar2(64),
      position        number
    )
/

drop table my_table
/
create table my_table( text varchar2(2000) )
/
insert into my_table values( '<text>available in future release</text>' )
/
insert into my_table values( '<text>available california future release</text>' )
/
insert into my_table values( '<text>indiana ind</text>' )
/

exec ctx_ddl.drop_preference     ( 'my_wl' )
exec ctx_ddl.create_preference   ( 'my_wl', 'BASIC_WORDLIST' )
exec ctx_ddl.set_attribute       ( 'my_wl', 'STEMMER', 'AUTO' )
exec ctx_ddl.set_attribute       ( 'my_wl', 'FUZZY_MATCH','AUTO');
/

exec ctx_ddl.drop_section_group  ( 'my_sec' )
exec ctx_ddl.create_section_group( 'my_sec', 'BASIC_SECTION_GROUP' )
exec ctx_ddl.add_field_section   ( 'my_sec',  'text', 'text' )

create index my_index on my_table( text ) 
indextype is ctxsys.context
parameters( 'section group my_sec wordlist my_wl' )
/

select token_text from dr$my_index$i
/

select * from my_table where contains( text, '(available in future release) within text' ) > 0
/

select * from my_table where contains( text, '(($available) within text) & (${in} within text)' ) > 0
/

exec ctx_query.explain('my_index', '(($available) within text) & (${in} within text)', 'xres')

select lpad(' ',2*(level-1))||level||'.'||position||' '||
       operation||' '||
       decode(options, null, null, options || ' ') ||
       object_name plan
  from xres
 start with id = 1 
connect by prior id = parent_id
/



