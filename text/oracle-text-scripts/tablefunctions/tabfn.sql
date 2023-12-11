create or replace type idstr is object
( id number,
  str varchar2(4000)
);

create replace idstrtab is table of idstr;

create or replace function addx (id number, str varchar2(4000)) return idstrtab
begin
  return idstrtab( idstr(1, 'abc'), idstr(2, 'def'), idstr(3, 'ghi') );
end;
/

