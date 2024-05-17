create table gw (text varchar2(2000));

insert into gw values ('greenwich');
insert into gw values ('greenwich mean time');
insert into gw values ('greenwich mean time is the time at greenwich');
insert into gw values ('greenwich is the origin of greenwich mean time');
insert into gw values ('greenwich greenwich mean time greenwich');
insert into gw values ('the time is 11 greenwich mean time');
insert into gw values ('greenwich mean time foo greenwich mean time foo greenwich mean time');
insert into gw values ('greenwich mean time foo greenwich mean time foo greenwich mean time greenwich');

create index gwi on gw(text) indextype is ctxsys.context;

select * from gw where contains (text, 'greenwich') > 0;
