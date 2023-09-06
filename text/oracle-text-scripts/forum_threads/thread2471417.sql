set echo on
set timing on

drop table prod_search_det2
/
create table prod_search_det2 
  (prod_details varchar2(1000)
  ,sign varchar2(42)
  )
/

declare
  sign varchar2(1);
begin
  for k in 1..67000 loop
    case mod(k, 3)
      when 0 then sign := 'K';
      when 1 then sign := 'S';
      else sign := 'C';
    end case;
    insert into prod_search_det2 values ( 
        dbms_random.string('u', 5) || ' '
      ||dbms_random.string('u', 5) || ' '
      ||dbms_random.string('u', 5) || ' '
      ||dbms_random.string('u', 5)
      , sign );
  end loop;
end;
/

select count(*) from prod_search_det2
/

exec ctx_ddl.drop_section_group   ( 'my_secgroup' )
exec ctx_ddl.create_section_group ( 'my_secgroup', 'BASIC_SECTION_GROUP' )
exec ctx_ddl.add_field_section    ( 'my_secgroup', 'K', 'K' )
exec ctx_ddl.add_field_section    ( 'my_secgroup', 'S', 'S' )
exec ctx_ddl.add_field_section    ( 'my_secgroup', 'C', 'C' )

exec ctx_ddl.drop_preference  ( 'my_datastore' )
exec ctx_ddl.create_preference( 'my_datastore', 'MULTI_COLUMN_DATASTORE')
exec ctx_ddl.set_attribute    ( 'my_datastore', 'COLUMNS', '''<''|| sign || ''>XXX'' || prod_details || ''</''|| sign ||''>''' )

exec ctx_ddl.drop_preference  ( 'my_wl' )
exec ctx_ddl.create_preference( 'my_wl', 'BASIC_WORDLIST' )
exec ctx_ddl.set_attribute    ( 'my_wl', 'SUBSTRING_INDEX', 'true' )

create index prod_search_idx on prod_search_det2( prod_details )
indextype is ctxsys.context
parameters( 'section group my_secgroup datastore my_datastore wordlist my_wl')
/

-- simple query:
select * from
  (select prod_details from prod_search_det2 
   where contains( prod_details, '%234% within K' ) > 0
  )
where rownum < 15
/

column prod_details format a40
column sign format a10


-- create a progressive relaxation query

create or replace function create_my_contains_clause( searchterm varchar2 ) 
return varchar2 is 
begin
  return '
<query>
  <textquery>
    <progression>
      <seq> XXX' || searchterm || '% WITHIN S </seq>
      <seq> XXX' || searchterm || '% WITHIN K </seq>
      <seq> XXX' || searchterm || '% WITHIN C </seq>
      <seq> ' || searchterm || '% WITHIN S </seq>
      <seq> ' || searchterm || '% WITHIN K </seq>
      <seq> ' || searchterm || '% WITHIN C </seq>
      <seq> %' || searchterm || '% WITHIN K </seq>
      <seq> %' || searchterm || '% WITHIN S </seq>
      <seq> %' || searchterm || '% WITHIN C </seq>
    </progression>
  </textquery>
</query>';
end;
/
show err

set pagesize 10

select create_my_contains_clause('bcd') from dual
/

select * from
  ( select prod_details, sign from prod_search_det2 
    where contains( prod_details, create_my_contains_clause( 'bcd' ), 1) > 0
    order by score(1) desc
  )
where rownum < 31
/


