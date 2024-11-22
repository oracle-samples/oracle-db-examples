
begin
  ctx_cd.drop_cdstore('t256k');
exception when others then null;
end;
/

exec ctx_cd.create_cdstore('t256k', 'tab256k')

begin
  ctx_cd.add_column ( 't256k', 'text' );
  ctx_cd.add_column ( 't256k', 'num', 
      min_int => 0, max_int => 65535, visible=>false);
  ctx_cd.add_column ( 't256k', 'the_date', 
      min_date => '1-JAN-1990', max_date => '09-MAY-2004', visible=>false);
end;
/

create index t256k_num    on tab256k (num);

create index t256k_date   on tab256k (the_date);

create index t256k_text   on tab256k (text)
  indextype is ctxsys.context;

create index t256k_concat on tab256k (concat)
  indextype is ctxsys.context parameters
  ('datastore t256k section group t256k');

select count(*) from ctx_user_index_errors;

