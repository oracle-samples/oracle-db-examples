drop table addressSearch;

create table addressSearch (address varchar2(2000));

insert into addressSearch values ('Stockholm, Stockrosvägen');
insert into addressSearch values ('Stockholm, Stockbergsvägen');
insert into addressSearch values ('Stockholm, Othervägen');
insert into addressSearch values ('London, Stockstreet');

-- try some repeated words to make sure it still works correctly
insert into addressSearch values ('Stockholm Stockholm, Stockrosvägen');
insert into addressSearch values ('Stockholm, Stockrosvägen Stockrosvägen');

create index addressIndex on addressSearch(address) 
indextype is ctxsys.context
/

select * from addressSearch where contains (address, 'Stockholm AND (Stock% MINUS Stockholm)') > 0;
