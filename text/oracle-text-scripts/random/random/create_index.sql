exec ctx_ddl.drop_preference  ('mywl')
exec ctx_ddl.create_preference('mywl', 'basic_wordlist')
exec ctx_ddl.set_attribute    ('mywl', 'SUBSTRING_INDEX', 'YES')

drop index docs_index;

set timing on

exec ctx_output.start_log('docs_index1')

create index docs_index on docs (text)
indextype is ctxsys.context
parameters ('wordlist mywl memory 500M')
local;

exec ctx_output.end_log;
