drop package helperpackage;

drop type aliastable;

create or replace type aliasrecord as object (name varchar2(4000),lang varchar2(4000));
/
create or replace type aliastable is table of aliasrecord;
/

create or replace package helperpackage as

  function splitaliases (aliasstring varchar2) return aliastable;
  procedure test;

end helperpackage;
/
show err
list

create or replace package body helperpackage as 
  
function splitaliases (aliasstring varchar2) return aliastable is 
  retaliases aliastable;
  w varchar2(32767);
  p pls_integer;
  a varchar2(32767);
  l_index pls_integer := 1;
  l_pipe_index pls_integer;
  lang varchar2(32767);
  name varchar2(32767);
begin
  w := aliasstring || '|';
  retaliases := aliastable();
  loop
   l_pipe_index := instr(w, '|', l_index);
   exit when l_pipe_index = 0;
   a := substr(w, l_index, (l_pipe_index - l_index));
   p := instr(a, ':'); 
   retaliases.extend;
   lang := substr(a, p+1);
   name := substr(a, 1, p - 1);
   begin
      retaliases(retaliases.count) := aliasrecord( name, lang);   l_index := l_pipe_index + 1;
   exception when others then
      dbms_output.put_line('Name:'||name);
      dbms_output.put_line('Lang:'||lang);
      exit;
   end;
  end loop;
  return retaliases;

  return retaliases;
end;

procedure test is 
  a aliastable;
begin
  a :=  splitaliases ('USA:ENG|UHENDRIIGID:EST|ÜHENDRIIGID:EST|YHDYSVALLAT:FIN|ETATS UNIS:FRE|ÉTATS UNIS:FRE|VEREINIGTE STAATEN:GER');
  for i in 1 .. a.count loop
     dbms_output.put_line(a(i).lang || ': ' ||  a(i).name);
  end loop;
end;

end helperpackage;
/

show err
list

set serverout off

SET SERVEROUTPUT OFF
begin
  Dbms_Output.Enable ('localhost', 1599, 'WE8ISO8859P1');
end;
/
-- exec helperpackage.test

drop table aliases;
create table aliases (area_id number, area_name varchar2(4000), lang varchar2(500), alias varchar2(4000));

set timing on

begin
  for c in ( select area_id, area_name, aliases from eloc_work ) loop
     insert into aliases select c.area_id, c.area_name, lang, name from table(helperpackage.splitaliases(c.aliases));
  end loop;
end;
/

column lang format a10
column alias format a30
column area_name format a20

delete from aliases where area_name = alias;

commit;

select count(*) from aliases;

