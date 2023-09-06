drop table xmltest;

create table xmltest (pk number primary key, text varchar2(2000));

insert into xmltest values (1,
'<xml> '||
'   <keys> '||
'     <ISSUE> '||
'       <ALTERNATIVE-INVESTMENT-IND>Y</ALTERNATIVE-INVESTMENT-IND> ' ||
'     </ISSUE> ' ||
'   </keys> ' ||
'</xml>');

insert into xmltest values (2,
'<xml> '||
'   <keys> '||
'     <ISSUE> '||
'       <ALTERNATIVE-INVESTMENT-IND>N</ALTERNATIVE-INVESTMENT-IND> ' ||
'     </ISSUE> ' ||
'   </keys> ' ||
'</xml>');


commit;

create index xmlind on xmltest (text) indextype is ctxsys.context
parameters('section group ctxsys.path_section_group');

column text format a50

select * from xmltest where contains (text, 'Y inpath(/xml/keys/ISSUE/ALTERNATIVE-INVESTMENT-IND)') > 0;

select * from xmltest where contains (text, 'Y inpath(/xml/keys/ISSUE/ALTERNATIVE-INVESTMENT-IND)') = 0;

select * from xmltest where contains (text, 'haspath(/xml/keys/ISSUE/ALTERNATIVE-INVESTMENT-IND=''Y'')') > 0;

select * from xmltest where contains (text, 'haspath(/xml/keys/ISSUE/ALTERNATIVE-INVESTMENT-IND!=''Y'')') > 0;

select * from xmltest where contains (text, 'haspath(/xml/keys/ISSUE/ALTERNATIVE-INVESTMENT-IND=''Y'')') = 0;




