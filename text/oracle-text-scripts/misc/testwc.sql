drop table test;
create table test (pk number primary key, thexml varchar2(4000));

insert into test values (1, 
'<SEARCH KEY="XMIGRX634"> </SEARCH> <SEARCH KEY="XMIGR1634"> </SEARCH>');
insert into test values (2,
'<SEARCH KEY="XMIGR2634"> </SEARCH> <SEARCH KEY="XMIGR3634"> </SEARCH>');
insert into test values (3,
'<SEARCH KEY="34XYZ"> </SEARCH> <SEARCH KEY="34XYZ"> </SEARCH>');

create index myindex on test(thexml) indextype is ctxsys.context
parameters ('section group ctxsys.auto_section_group');

select pk, thexml from test where contains (thexml, '3% within search@key') > 0;
