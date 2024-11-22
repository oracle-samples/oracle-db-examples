drop table people;

set echo on

create table people (id number, name varchar2(60));

insert all
  into people values (1, 'Eichinger')
  into people values (2, 'Mairhofer')
  into people values (3, 'Mairhofer')
  into people values (4, 'Mairhofer')
  into people values (5, 'Maier')
  into people values (6, 'Eichinger')
  into people values (7, 'Maier')
  into people values (8, 'Maier')
  into people values (9, 'Meisenberger')
  into people values (10, 'Eichinger')
  into people values (11, 'Meier')
  into people values (12, 'Meier-Weber')
  into people values (13, 'Maier')
  into people values (14, 'Maierhofer')
  into people values (15, 'Maier')
  into people values (16, 'Maier')
  into people values (17, 'Eichinger')
  into people values (18, 'Mairhofer')
  into people values (19, 'Maierhofer')
  into people values (20, 'Maier')
  into people values (21, 'Meyer')
  into people values (22, 'Meyer')
  into people values (23, 'Maierhofer')
  into people values (24, 'Eichinger')
  into people values (25, 'Eichinger')
  into people values (26, 'Eichinger')
  into people values (27, 'Maier')
  into people values (28, 'Maier')
  into people values (29, 'Mairhofer')
  into people values (30, 'aier')
  select * from dual
/

create index peopleindex on people(name) indextype is ctxsys.context
parameters('section group mysections')
/


create or replace procedure namesearch (search varchar2) is
   type         nametable is table of varchar2(64) index by binary_integer;
   names        nametable;
   wc_names     varchar2(32767) := '';
   conjunct     varchar2(4)     := '';
   idx          binary_integer;
begin
   -- first query gets fuzzy matches
   for c in ( select id, name from people where contains( name, 'fuzzy((' || search || '),60,40,N)', 1 ) > 0
              order by score(1) desc ) loop
     dbms_output.put_line(c.id || ': ' || c.name);
     names(c.id) := c.name;

   end loop;

   -- build a new search string from previous results
   idx := names.first;
   while idx is not null loop
      wc_names := wc_names || conjunct || names(idx) || '%';
      idx := names.next(idx);
      conjunct := ' OR ';
   end loop;
   dbms_output.put_line('WildCard query is: '|| wc_names);

   -- second query gets wild carded terms
   for c in ( select id, name from people where contains( name, wc_names, 1 ) > 0
              order by score(1) desc ) loop
      -- only output this if we haven't had it already
      if not names.exists(c.id) then
         dbms_output.put_line(c.id || ': ' || c.name);
      end if;
   end loop;
end;
/

set serveroutput on size 1000000

execute namesearch( 'meier')
