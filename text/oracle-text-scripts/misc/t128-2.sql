
begin
  ctx_cd.drop_cdstore('t128k');
exception when others then null;
end;
/

exec ctx_cd.create_cdstore('t128k', 'tab128k')

begin
  ctx_cd.add_column ( 't128k', 'text' );
  ctx_cd.add_column ( 't128k', 'num', 
      min_int => 0, max_int => 65535, visible=>false);
  ctx_cd.add_column ( 't128k', 'the_date', 
      min_date => '1-JAN-1990', max_date => '09-MAY-2004', visible=>false);
end;
/

create index t128k_num    on tab128k (num);

create index t128k_date   on tab128k (the_date);

create index t128k_text   on tab128k (text)
  indextype is ctxsys.context;

create index t128k_concat on tab128k (concat)
  indextype is ctxsys.context parameters
  ('datastore t128k section group t128k');

select count(*) from ctx_user_index_errors;

