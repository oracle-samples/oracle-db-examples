drop table testtab;
create table testtab(txt varchar2(80));

insert into testtab values ('fou');

exec ctx_ddl.drop_preference('FNTC_Lexer100')
exec ctx_ddl.drop_preference('FNTC_Word_List100')

BEGIN
     ctx_ddl.create_preference('FNTC_Lexer100', 'BASIC_LEXER');
     ctx_ddl.set_attribute('FNTC_Lexer100', 'base_letter', 'yes');
     ctx_ddl.set_attribute('FNTC_Lexer100', 'base_letter_type', 'GENERIC');
     ctx_ddl.set_attribute('FNTC_Lexer100', 'override_base_letter', 'false');
     ctx_ddl.set_attribute('FNTC_Lexer100', 'mixed_case', 'NO');
     ctx_ddl.set_attribute('FNTC_Lexer100', 'index_stems', 'CATALAN');
     ctx_ddl.set_attribute('FNTC_Lexer100', 'index_text', 'YES');
     ctx_ddl.create_preference('FNTC_Word_List100', 'BASIC_WORDLIST');
     ctx_ddl.set_attribute('FNTC_Word_List100', 'substring_index', 'true');
     ctx_ddl.set_attribute('FNTC_Word_List100', 'prefix_index', 'true');
     ctx_ddl.set_attribute('FNTC_Word_List100', 'prefix_min_length', '1');
     ctx_ddl.set_attribute('FNTC_Word_List100', 'prefix_max_length', '50');
     ctx_ddl.set_attribute('FNTC_Word_List100', 'wildcard_maxterms', '50');
END;
/

create index testindex on testtab(txt) 
indextype is ctxsys.context 
parameters ('lexer fntc_lexer100 wordlist fntc_word_list100 stoplist ctxsys.empty_stoplist');

select token_type, token_text from dr$testindex$i;

-- select * from testtab where contains (txt, '$estigueres') > 0;
select * from testtab where contains (txt, '$som') > 0;

