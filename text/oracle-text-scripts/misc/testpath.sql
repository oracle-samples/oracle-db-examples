drop table mytable;

CREATE TABLE mytable (
id number(10,0),
fullpath varchar2(1000),
o_format varchar2(10));

-- preference: ignore case

exec ctx_ddl.drop_preference('my_lexer')

begin
ctx_ddl.create_preference('my_lexer', 'BASIC_LEXER');
ctx_ddl.set_attribute('my_lexer', 'mixed_case', 'no');
end;
/

exec ctx_ddl.drop_preference('no_path')

-- preference: no path (that means I store the full path in the 'fullpath' column)
begin
ctx_ddl.create_preference('no_path', 'FILE_DATASTORE');
end;
/

-- create index: no filters, no stoplists - just give me everything!
CREATE INDEX my_fullindex on mytable(fullpath)
INDEXTYPE IS ctxsys.context
PARAMETERS('DATASTORE no_path FILTER ctxsys.null_filter LEXER my_lexer STOPLIST ctxsys.empty_stoplist FORMAT COLUMN o_format');

-- insert some data
INSERT INTO mytable (id, fullpath, o_format) VALUES(1, 'C:\test.txt', null);

-- sync index #1 - this is what I do for a database storage index
CALL ctx_ddl.sync_index('my_fullindex');

-- sync index #2 - this is what I do because I read it in here
--UPDATE mytable 
--SET fullpath = fullpath
--/

-- query the table:
SELECT id
FROM mytable
WHERE CONTAINS(fullpath, 'document%') > 0
/
