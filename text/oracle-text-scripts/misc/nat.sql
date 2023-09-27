create table mytext (pk number primary key, text varchar2(2000));

insert into mytext values (1,
'yesterday we went camping and hiking in New England');
insert into mytext values (2,
'yesterday we went camping in New England');
insert into mytext values (3,
'yesterday we went hiking in England');
insert into mytext values (4,
'yesterday we went to a new camp in England');
insert into mytext values (5,
'New England is a great place for camping');

commit;

create index myindex on mytext(text) indextype is ctxsys.context;

