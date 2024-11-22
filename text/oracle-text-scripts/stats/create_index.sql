old   1: select ctx_report.create_index_script( '&index_name' ) from dual
new   1: select ctx_report.create_index_script( 'fooindex' ) from dual
begin
  ctx_ddl.create_preference('"FOOINDEX_DST"','DIRECT_DATASTORE');
end;
/

begin
  ctx_ddl.create_preference('"FOOINDEX_FIL"','NULL_FILTER');
end;
/

begin
  ctx_ddl.create_section_group('"FOOINDEX_SGP"','BASIC_SECTION_GROUP');
  ctx_ddl.add_field_section('"FOOINDEX_SGP"','FIRST','FIRST',FALSE);
  ctx_ddl.add_field_section('"FOOINDEX_SGP"','LAST','LAST',FALSE);
end;
/

begin
  ctx_ddl.create_preference('"FOOINDEX_LEX"','BASIC_LEXER');
end;
/

begin
  ctx_ddl.create_preference('"FOOINDEX_WDL"','BASIC_WORDLIST');
  ctx_ddl.set_attribute('"FOOINDEX_WDL"','STEMMER','ENGLISH');
  ctx_ddl.set_attribute('"FOOINDEX_WDL"','FUZZY_MATCH','GENERIC');
end;
/

begin
  ctx_ddl.create_stoplist('"FOOINDEX_SPL"','BASIC_STOPLIST');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','Mr');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','Mrs');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','Ms');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','a');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','all');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','almost');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','also');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','although');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','an');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','and');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','any');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','are');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','as');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','at');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','be');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','because');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','been');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','both');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','but');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','by');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','can');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','could');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','d');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','did');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','do');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','does');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','either');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','for');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','from');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','had');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','has');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','have');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','having');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','he');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','her');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','here');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','hers');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','him');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','his');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','how');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','however');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','i');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','if');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','in');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','into');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','is');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','it');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','its');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','just');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','ll');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','me');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','might');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','my');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','no');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','non');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','nor');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','not');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','of');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','on');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','one');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','only');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','onto');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','or');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','our');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','ours');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','s');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','shall');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','she');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','should');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','since');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','so');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','some');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','still');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','such');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','t');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','than');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','that');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','the');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','their');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','them');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','then');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','there');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','therefore');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','these');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','they');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','this');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','those');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','though');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','through');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','thus');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','to');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','too');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','until');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','ve');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','very');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','was');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','we');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','were');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','what');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','when');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','where');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','whether');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','which');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','while');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','who');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','whose');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','why');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','will');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','with');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','would');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','yet');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','you');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','your');
  ctx_ddl.add_stopword('"FOOINDEX_SPL"','yours');
end;
/

begin
  ctx_ddl.create_preference('"FOOINDEX_STO"','BASIC_STORAGE');
  ctx_ddl.set_attribute('"FOOINDEX_STO"','R_TABLE_CLAUSE','lob (data) store as (
cache)');
  ctx_ddl.set_attribute('"FOOINDEX_STO"','I_INDEX_CLAUSE','compress 2');
end;
/


begin
  ctx_output.start_log('FOOINDEX_LOG');
end;
/

create index "ROGER"."FOOINDEX"
  on "ROGER"."FOO"
      ("BAR")
  indextype is ctxsys.context
  parameters('
    datastore       "FOOINDEX_DST"
    filter          "FOOINDEX_FIL"
    section group   "FOOINDEX_SGP"
    lexer           "FOOINDEX_LEX"
    wordlist        "FOOINDEX_WDL"
    stoplist        "FOOINDEX_SPL"
    storage         "FOOINDEX_STO"
  ')
/

begin
  ctx_output.end_log;
end;
/



