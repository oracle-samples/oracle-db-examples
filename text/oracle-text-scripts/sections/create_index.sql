begin
  ctx_ddl.create_preference('"TC_DST"','DIRECT_DATASTORE');
end;
/

begin
  ctx_ddl.create_preference('"TC_FIL"','NULL_FILTER');
end;
/

begin
  ctx_ddl.create_section_group('"TC_SGP"','BASIC_SECTION_GROUP');
  ctx_ddl.add_special_section('"TC_SGP"','SENTENCE');
  ctx_ddl.add_special_section('"TC_SGP"','PARAGRAPH');
end;
/

begin
  ctx_ddl.create_preference('"TC_LEX"','BASIC_LEXER');
end;
/

begin
  ctx_ddl.create_preference('"TC_WDL"','BASIC_WORDLIST');
  ctx_ddl.set_attribute('"TC_WDL"','STEMMER','ENGLISH');
  ctx_ddl.set_attribute('"TC_WDL"','FUZZY_MATCH','GENERIC');
end;
/

begin
  ctx_ddl.create_stoplist('"TC_SPL"','BASIC_STOPLIST');
end;
/

begin
  ctx_ddl.create_preference('"TC_STO"','BASIC_STORAGE');
  ctx_ddl.set_attribute('"TC_STO"','R_TABLE_CLAUSE','lob (data) store as (cache)
');
  ctx_ddl.set_attribute('"TC_STO"','I_INDEX_CLAUSE','compress 2');
end;
/


begin
  ctx_output.start_log('TC_LOG');
end;
/

create index "TESTUSER"."TC"
  on "TESTUSER"."T"
      ("C")
  indextype is ctxsys.context
  parameters('
    datastore       "TC_DST"
    filter          "TC_FIL"
    section group   "TC_SGP"
    lexer           "TC_LEX"
    wordlist        "TC_WDL"
    stoplist        "TC_SPL"
    storage         "TC_STO"
  ')
/

begin
  ctx_output.end_log;
end;
/



