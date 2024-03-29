-- example of a testcase on an MS Word file using Chinese characters
-- to see the characters in SQL*Plus you will need to set NLS_LANG before
-- starting SQL*Plus, eg:
-- export NLS_LANG=american_america.al32utf8

-- this example uses FILE_DATASTORE and the CHINESE_VGRAM_LEXER
-- it relies on a MSWord file /mnt/s/NLP.docx - change path and file to a 
-- suitable Chinese text file

connect sys/password as sysdba

drop user chtest cascade;

create user chtest identified by chtest;
grant connect,resource,ctxapp,unlimited tablespace to chtest;

-- in 19c you would use:
grant text datastore access to chtest;

-- in 11c and earlier you would use this instead:
-- exec ctxsys.ctx_adm.set_parameter('FILE_ACCESS_ROLE', 'CTXAPP')

connect chtest/chtest

create table mydocs (id number primary key, filename varchar2(2000));

insert into mydocs values (1, '/mnt/s/NLP.docx');

exec ctx_ddl.create_preference('mylexer', 'CHINESE_VGRAM_LEXER')

create index mydocsind on mydocs(filename)
indextype is ctxsys.context
parameters( 'lexer mylexer datastore ctxsys.file_datastore' );

select * from ctx_user_index_errors;

select filename from mydocs where contains( filename, '验班') > 0;

select filename from mydocs where contains( filename, '我们运用语') > 0;

select filename from mydocs where contains( filename, '我们运用语 AND 象显示我') > 0;



