-- add a field section to an existing index
-- obviously will only be indexed in new or updated records

exec ctx_ddl.drop_section_group('TEST_FIELD_SG')

exec ctx_ddl.create_section_group('TEST_FIELD_SG', 'BASIC_SECTION_GROUP');
exec ctx_ddl.add_field_section('TEST_FIELD_SG','A1','A1',TRUE);

drop table test_field;
CREATE TABLE test_field (content VARCHAR2(4000));
INSERT INTO test_field (content) VALUES ('<ROOT><A1>eugen</A1></ROOT>');
CREATE INDEX test_field_ox ON test_field (content) indextype IS ctxsys.context parameters ('SECTION GROUP TEST_FIELD_SG SYNC (ON COMMIT)');
SELECT COUNT(*) FROM test_field WHERE contains(content,'eugen')>0;
SELECT COUNT(*) FROM test_field WHERE contains(content,'eugen within A1')>0;

ALTER INDEX test_field_ox PARAMETERS ('ADD FIELD SECTION A2 TAG A2 VISIBLE');

INSERT INTO test_field (content) VALUES ('<ROOT><A2>iacob</A2></ROOT>');
commit;

SELECT COUNT(*) FROM test_field WHERE contains(content,'iacob within A2')>0;
