create table t (pk number primary key, the_url varchar2(2000));

insert into t values (1,'http://www.nwfsc.noaa.gov/pubs/tm/tm187/Stempel.html');
insert into t values (2,'http://www.nwfsc.noaa.gov/pubs/tm/tm1/tm1.htm');
insert into t values (3,'http://www.nwfsc.noaa.gov/pubs/tm/tm193/otm193.pdf');
insert into t values (4,'http://www.nwfsc.noaa.gov/pubs/tm/tm13/AppendixA.pdf');

commit;

create index t_index on t(the_url) indextype is ctxsys.context
parameters ('datastore ctxsys.url_datastore');

select count(*), distinct(err_text) from ctx_user_index_errors
group by err_text;

