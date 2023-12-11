-- inso_filter was the earlier name for AUTO_FILTER
-- this checks whether it can still be used (it can)
-- user must have TEXT DATASTORE ACCESS role

-- replace this with a proper MSWord doc for a better test:
! echo hello world > /tmp/test.doc

drop table x;

create table x (x varchar2(2000));
insert into x values ('/tmp/test.doc');

create index xi on x(x) indextype is ctxsys.context
parameters ('filter ctxsys.inso_filter datastore ctxsys.file_datastore');

select token_text from dr$xi$i;
