drop table tdrbpot3_tab;

create table tdrbpot3_tab (id number primary key, txt clob)
 partition by range(id)
 ( partition p1 values less than (2),
  partition p2 values less than (5),
  partition p3 values less than (10)
 );

insert into tdrbpot3_tab(id,txt) values(1,'first <A> term1 </A> first');
insert into tdrbpot3_tab(id,txt) values (2,'second  <B> term2 </B> second');
insert into tdrbpot3_tab(id,txt) values (3, '<A>Oracle Text adds powerful
 search and intelligent text management to the Oracle database.  Complete.  
You can search and manage documents, web pages, catalog entries in more than
150 formats in any language.  Provides a complete text query language and
complete character support.  Simple.  You can index and search text using
SQL. Oracle Text Management can be done using Oracle Enterprise Manager - a
GUI tool.  Fast.  You can search millions of documents, document,web pages,
catalog entries using the power and scalability of the database.  
Intelligent.  Oracle Text''s unique knowledge-base enables you to search,
classify, manage documents, clusters and summarize text based on its meaning
as well as its content.</A> ');
insert into tdrbpot3_tab(id,txt) values (4, 'Oracle Text adds powerful search
and intelligent text management to the Oracle database.  Complete.  You can
search and manage documents, web pages, catalog entries in more than 150
formats in any language.  Provides a complete text query language and
complete character support.  Simple.  You can index and search text using
SQL. Oracle Text Management can be done using Oracle Enterprise Manager - a
GUI tool.  Fast.  You can search millions of documents, document,web pages,
catalog entries using the power and scalability of the database.  
Intelligent.  Oracle Text''s unique knowledge-base enables you to search,
classify, manage documents, clusters and summarize text based on its meaning
as well as its content. ');

commit;
execute ctx_ddl.drop_preference('tdrbpot3_sto')
execute ctx_ddl.create_preference('tdrbpot3_sto','basic_storage');
execute ctx_ddl.set_attribute('tdrbpot3_sto','forward_index','T');
execute ctx_ddl.set_attribute('tdrbpot3_sto','stage_itab','T');
execute ctx_ddl.set_attribute('tdrbpot3_sto','save_copy','NONE');
execute ctx_ddl.set_attribute('tdrbpot3_sto', 'SAVE_COPY_MAX_SIZE', '1000m');

exec ctx_ddl.drop_section_group('tdrbpot3_sg')
exec ctx_ddl.create_section_group('tdrbpot3_sg','basic_section_group');
exec ctx_ddl.add_sdata_section('tdrbpot3_sg','sec01','a', 'varchar2');
exec ctx_ddl.add_field_section('tdrbpot3_sg','sec02','b', false);

create index tdrbpot3_idx on tdrbpot3_tab(txt) indextype is ctxsys.context
  local parameters ('storage tdrbpot3_sto section group tdrbpot3_sg');

