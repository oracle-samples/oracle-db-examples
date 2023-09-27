SQL> select ctx_report.create_index_script('foobar') from dual;
begin
  ctx_ddl.create_preference('"FOOBAR_DST"','DIRECT_DATASTORE');
end;
/

begin
  ctx_ddl.create_preference('"FOOBAR_FIL"','NULL_FILTER');
end;
/

begin
  ctx_ddl.create_section_group('"FOOBAR_SGP"','PATH_SECTION_GROUP');
  ctx_ddl.add_sdata_section('"FOOBAR_SGP"','CTXSYS.JSON_SEARCH_GROUPNUM*','num*'
,'NUMBER');
  ctx_ddl.add_sdata_section('"FOOBAR_SGP"','CTXSYS.JSON_SEARCH_GROUPTS*','ts*','
VARCHAR2');
end;
/

begin
  ctx_ddl.create_preference('"FOOBAR_LEX"','BASIC_LEXER');
end;
/

begin
  ctx_ddl.create_preference('"FOOBAR_WDL"','BASIC_WORDLIST');
  ctx_ddl.set_attribute('"FOOBAR_WDL"','STEMMER','ENGLISH');
  ctx_ddl.set_attribute('"FOOBAR_WDL"','FUZZY_MATCH','GENERIC');
end;
/

begin
  ctx_ddl.create_preference('"FOOBAR_STO"','BASIC_STORAGE');
  ctx_ddl.set_attribute('"FOOBAR_STO"','R_TABLE_CLAUSE','lob (data) store as (ca
che)');
  ctx_ddl.set_attribute('"FOOBAR_STO"','I_INDEX_CLAUSE','compress 2');
  ctx_ddl.set_attribute('"FOOBAR_STO"','STAGE_ITAB','YES');
  ctx_ddl.set_attribute('"FOOBAR_STO"','STAGE_ITAB_MAX_ROWS','10000');
end;
/

create index "ROGER"."FOOBAR"
  on "ROGER"."FOO"
      ("BAR")
  indextype is ctxsys.context_v2
  parameters('
    datastore       "FOOBAR_DST"
    filter          "FOOBAR_FIL"
    section group   "FOOBAR_SGP"
    lexer           "FOOBAR_LEX"
    wordlist        "FOOBAR_WDL"
    stoplist        "CTXSYS"."EMPTY_STOPLIST"
    storage         "FOOBAR_STO"
    fast_dml
    sync (on commit)
  ')
/


SQL> spool off
