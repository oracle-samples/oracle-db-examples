drop table neartest;
create table neartest (pk number primary key, text varchar2(2000));

insert into neartest values (1,'alpha beta dog alpha beta');
insert into neartest values (2,'alpha one two three four five six beta ten nine alpha eight seven beta');
insert into neartest values (3,'alpha eight seven beta');
insert into neartest values (4,'alpha beta');
insert into neartest values (5,'alpha one two three four five six beta');
insert into neartest values (6,'alpha one two beta');
insert into neartest values (7,'alpha one beta');
insert into neartest values (8,
'she should have died hereafter, there would have been time for such a word.
Tomorrow and tomorrow and tomorrow creeps in its petty pace from day to day,
til the last sylable of recorded time. Out, out brief alpha candle, life is 
but a poor player who struts and frets his beta stuff upon the stage and then
is heard no more. Tis a tale told by an idiot, full of sound and fury, signifying
nothing.');
insert into neartest values (9,'alpha one two three four five six seven eight
nine beta');
insert into neartest values (10,'alpha one two three four five six seven eight
nine ten beta');
insert into neartest values (11,'alpha one two three four five six seven eight
nine ten eleven beta');
insert into neartest values (12,'alpha one two three four five six seven eight
nine ten eleven twelve beta');
 
commit;

create index neartestindex on neartest(text) indextype is ctxsys.context;

column score(1) format 99999
column text format a70

select score(1), text from neartest 
where contains (text, 'near((alpha, beta))', 1)>0;

select score(1), text from neartest 
where contains (text, 'near((alpha, beta), 2)', 1)>0;

select score(1), text from neartest 
where contains (text, 'near((alpha, beta), 1)', 1)>0;

select score(1), text from neartest 
where contains (text, 'near((alpha, beta), 0)', 1)>0;
