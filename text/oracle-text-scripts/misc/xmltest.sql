drop table xmltest;

create table xmltest (pk number primary key, text varchar2(2000));

insert into xmltest values (1,
'<foo> '||
'   <attr> '||
'     <name lang="de-DE" type="String">Schuh</name> '||
'     <name lang="en-US" type="String">Shoe</name> '||
'     <size type="int">42<size> '||
'   </attr> '||
'</foo> ');

insert into xmltest values (2,
'<foo> '||
'   <attr> '||
'     <name lang="de-DE" type="String">Schuh</name> '||
'     <name lang="en-US" type="String">Shoe</name> '||
'     <size type="int">21<size> '||
'   </attr> '||
'   <attr> '||
'     <name lang="de-DE" type="String">Koat</name> '||
'     <name lang="en-US" type="String">Coat</name> '||
'     <size type="int">42<size> '||
'   </attr> '||
'</foo> ');

commit;

create index xmlind on xmltest (text) indextype is ctxsys.context
parameters('section group ctxsys.path_section_group');
