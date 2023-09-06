set feedback on

exec ctx_ddl.drop_preference('addressds')
begin
    ctx_ddl.create_preference('addressds', 'MULTI_COLUMN_DATASTORE');
    ctx_ddl.set_attribute('addressds', 'columns', 'address as address');
end;
/

exec ctx_ddl.drop_section_group('addressgroup')
begin
    ctx_ddl.create_section_group('addressgroup', 'BASIC_SECTION_GROUP');
    ctx_ddl.add_ndata_section('addressgroup', 'ADDRESS', 'ADDRESS');
end;
/

drop index myindex;

CREATE INDEX myindex ON vertices(address) INDEXTYPE IS CTXSYS.CONTEXT parameters('section group addressgroup datastore addressds');
-- CREATE INDEX myindex ON vertices(address) INDEXTYPE IS CTXSYS.CONTEXT parameters('section group addressgroup');

SELECT VID, address, SCORE(1) FROM vertices WHERE CONTAINS (address, 'near2((xxyyzz liechtenstein qqwwkk))', 1) > 0 AND ROWNUM <= 10 ORDER BY SCORE(1) DESC;
