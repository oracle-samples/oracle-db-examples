CREATE OR REPLACE FUNCTION bchat_markup
  (p_index_name IN VARCHAR2,
   p_textkey    IN VARCHAR2,
   p_text_query IN VARCHAR2,
   p_plaintext  IN BOOLEAN  DEFAULT TRUE,
   p_starttag   IN VARCHAR2 DEFAULT '<< p_index_name,
        textkey    => p_textkey,
        text_query => p_text_query,
        restab     => v_clob,
        plaintext  => p_plaintext,
        starttag   => p_starttag,
        endtag     => p_endtag);
   RETURN v_clob;
END bchat_markup;
/
show err

drop table search_test;

create table search_test 
(
     data_id number(19),
     test_data clob
);
alter table search_test 
    add constraint search_test_pk primary key ( data_id ) ;

insert into search_test values (1, 'this is, the fust. test sentence ?? with ., some ??? content! ');
insert into search_test values (2, 'The quick, brown fox > jumps < over the lazy dog.');
insert into search_test values (3, 'Some !@#$%%^&*(()),.<>;:''"[]{}-_=+~ crazy char string ');
insert into search_test values (4, 'this is, the fust test sentence ?? with ., some ??? content! ');
insert into search_test values (5, 'this is, the fust; test sentence ?? with ., some ??? content! ');
insert into search_test values (6, 'this is, the fust: test sentence ?? with ., some ??? content! ');
insert into search_test values (7, 'this is, the fust? test sentence ?? with ., some ??? content! ');
insert into search_test values (8, 'this is, the fust! test sentence ?? with ., some ??? content! ');
insert into search_test values (9, 'this is, the fust@ test sentence ?? with ., some ??? content! ');
insert into search_test values (10, 'this is, the fust# test sentence ?? with ., some ??? content! ');
insert into search_test values (11, 'this is, the fust$ test sentence ?? with ., some ??? content! ');
insert into search_test values (12, 'this is, the fust% test sentence ?? with ., some ??? content! ');
insert into search_test values (13, 'this is, the fust^ test sentence ?? with ., some ??? content! ');
insert into search_test values (14, 'this is, the fust& test sentence ?? with ., some ??? content! ');
insert into search_test values (15, 'this is, the fust* test sentence ?? with ., some ??? content! ');
insert into search_test values (16, 'this is, the fust( test sentence ?? with ., some ??? content! ');
insert into search_test values (17, 'this is, the fust) test sentence ?? with ., some ??? content! ');
insert into search_test values (18, 'this is, the fust[ test sentence ?? with ., some ??? content! ');
insert into search_test values (19, 'this is, the fust] test sentence ?? with ., some ??? content! ');
insert into search_test values (20, 'this is, the fust{ test sentence ?? with ., some ??? content! ');
insert into search_test values (21, 'this is, the fust} test sentence ?? with ., some ??? content! ');
insert into search_test values (22, 'this is, the fust< test sentence ?? with ., some ??? content! ');
insert into search_test values (23, 'this is, the fust> test sentence ?? with ., some ??? content! ');
insert into search_test values (24, 'this is, the fust- test sentence ?? with ., some ??? content! ');
insert into search_test values (25, 'this is, the fust_ test sentence ?? with ., some ??? content! ');
insert into search_test values (26, 'this is, the fust= test sentence ?? with ., some ??? content! ');
insert into search_test values (27, 'this is, the fust+ test sentence ?? with ., some ??? content! ');
insert into search_test values (28, 'this is, the fust| test sentence ?? with ., some ??? content! ');
insert into search_test values (29, 'this is, the fust!! test sentence .. with ., some && content! ');

delete from search_test;
insert into search_test values (1, 'fust?') ;


exec ctx_ddl.drop_preference('test_lexer')
exec ctx_ddl.drop_preference('test_wordlist')

BEGIN
     CTX_DDL.CREATE_PREFERENCE('test_lexer', 'BASIC_LEXER');
     CTX_DDL.SET_ATTRIBUTE('test_lexer', 'printjoins', '?~!@#$%^*()_-+={}[]:;<>,./');
     CTX_DDL.SET_ATTRIBUTE('test_lexer', 'punctuations', ' ');     
     CTX_DDL.CREATE_PREFERENCE('test_wordlist', 'BASIC_WORDLIST');
--     CTX_DDL.SET_ATTRIBUTE('test_wordlist', 'SUBSTRING_INDEX', 'YES');
--     CTX_DDL.SET_ATTRIBUTE('test_wordlist', 'PREFIX_INDEX', 'TRUE');
--     CTX_DDL.SET_ATTRIBUTE('test_wordlist', 'PREFIX_MIN_LENGTH', '3');
--     CTX_DDL.SET_ATTRIBUTE('test_wordlist', 'PREFIX_MAX_LENGTH', '6');
END;
/

CREATE INDEX search_test_text_idx on search_test(test_data)
     INDEXTYPE IS CTXSYS.CONTEXT
          PARAMETERS ('
            DATASTORE CTXSYS.DEFAULT_DATASTORE
            FILTER CTXSYS.NULL_FILTER
            STOPLIST CTXSYS.EMPTY_STOPLIST
            LEXER test_lexer
            SYNC (EVERY "sysdate+(10/(24*60*60))")
            WORDLIST test_wordlist');

select data_id, bchat_markup('search_test_text_idx', data_id, 'fust\?')
from search_test
where contains(test_data, 'fust\?', 1) > 0
/

select * from search_test where contains (test_data, 'fust\&', 1) > 0;

select token_text from dr$search_test_text_idx$i ;
