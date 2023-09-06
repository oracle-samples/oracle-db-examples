connect scott/tiger

create table test (
NR  NUMBER not null,
TEST_TEXT VARCHAR2(500),
LANG VARCHAR2(3));

insert into test values (1 ,'Louis', 'English');
insert into test values (2 ,'Lowie', 'Dutch');
commit;

ctxload -user scott/tiger -thes -name mythes -file mythes.txt

begin
ctx_ddl.create_preference('"I_TEXT_MPR_NOM_LEX"','BASIC_LEXER');
ctx_ddl.set_attribute('"I_TEXT_MPR_NOM_LEX"','COMPOSITE','DUTCH');
end;
/

begin
ctx_ddl.create_preference('"I_TEXT_MPR_NOM_WDL"','BASIC_WORDLIST');
ctx_ddl.set_attribute('"I_TEXT_MPR_NOM_WDL"','STEMMER','DUTCH');
ctx_ddl.set_attribute('"I_TEXT_MPR_NOM_WDL"','FUZZY_MATCH','DUTCH');
end;
/

begin
ctx_ddl.create_stoplist('"I_TEXT_MPR_NOM_SPL"','BASIC_STOPLIST');
end;
/

create index  test_ix on test(TEST_TEXT)
  indextype is ctxsys.context
  parameters('
    lexer           "I_TEXT_MPR_NOM_LEX"
    wordlist        "I_TEXT_MPR_NOM_WDL"
    stoplist        "I_TEXT_MPR_NOM_SPL"
    sync (on commit)
  ')
/

select nr,test_text,  score(1)  as score    from test
where contains (test_text, '(fuzzy(syn(louis,mythes),60,25,weight))' ,1)>0
ORDER BY score DESC
/

NR TEST_TEXT       SCORE
---------- ---------- ----------
2 Lowie               4
1 Louis               4

insert into test values (3 ,'Louise', 'Dutch');
commit;

select nr,test_text,  score(1)  as score    from test
where contains (test_text, '(fuzzy(syn(louis,mythes),60,25,weight))' ,1)>0
ORDER BY score DESC
/

