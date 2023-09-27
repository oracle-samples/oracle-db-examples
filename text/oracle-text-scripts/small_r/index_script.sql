SQL> set longchunksize 500000
SQL> set trimspool on
SQL> set linesize 132
SQL> set pagesize 0
SQL> /
begin
  ctx_ddl.create_preference('"I_DST"','DIRECT_DATASTORE');
end;
/

begin
  ctx_ddl.create_preference('"I_FIL"','NULL_FILTER');
end;
/

begin
  ctx_ddl.create_section_group('"I_SGP"','NULL_SECTION_GROUP');
end;
/

begin
  ctx_ddl.create_preference('"I_LEX"','BASIC_LEXER');
end;
/

begin
  ctx_ddl.create_preference('"I_WDL"','BASIC_WORDLIST');
  ctx_ddl.set_attribute('"I_WDL"','STEMMER','ENGLISH');
  ctx_ddl.set_attribute('"I_WDL"','FUZZY_MATCH','GENERIC');
end;
/

begin
  ctx_ddl.create_stoplist('"I_SPL"','BASIC_STOPLIST');
  ctx_ddl.add_stopword('"I_SPL"','Mr');
  ctx_ddl.add_stopword('"I_SPL"','Mrs');
  ctx_ddl.add_stopword('"I_SPL"','Ms');
  ctx_ddl.add_stopword('"I_SPL"','a');
  ctx_ddl.add_stopword('"I_SPL"','all');
  ctx_ddl.add_stopword('"I_SPL"','almost');
  ctx_ddl.add_stopword('"I_SPL"','also');
  ctx_ddl.add_stopword('"I_SPL"','although');
  ctx_ddl.add_stopword('"I_SPL"','an');
  ctx_ddl.add_stopword('"I_SPL"','and');
  ctx_ddl.add_stopword('"I_SPL"','any');
  ctx_ddl.add_stopword('"I_SPL"','are');
  ctx_ddl.add_stopword('"I_SPL"','as');
  ctx_ddl.add_stopword('"I_SPL"','at');
  ctx_ddl.add_stopword('"I_SPL"','be');
  ctx_ddl.add_stopword('"I_SPL"','because');
  ctx_ddl.add_stopword('"I_SPL"','been');
  ctx_ddl.add_stopword('"I_SPL"','both');
  ctx_ddl.add_stopword('"I_SPL"','but');
  ctx_ddl.add_stopword('"I_SPL"','by');
  ctx_ddl.add_stopword('"I_SPL"','can');
  ctx_ddl.add_stopword('"I_SPL"','could');
  ctx_ddl.add_stopword('"I_SPL"','d');
  ctx_ddl.add_stopword('"I_SPL"','did');
  ctx_ddl.add_stopword('"I_SPL"','do');
  ctx_ddl.add_stopword('"I_SPL"','does');
  ctx_ddl.add_stopword('"I_SPL"','either');
  ctx_ddl.add_stopword('"I_SPL"','for');
  ctx_ddl.add_stopword('"I_SPL"','from');
  ctx_ddl.add_stopword('"I_SPL"','had');
  ctx_ddl.add_stopword('"I_SPL"','has');
  ctx_ddl.add_stopword('"I_SPL"','have');
  ctx_ddl.add_stopword('"I_SPL"','having');
  ctx_ddl.add_stopword('"I_SPL"','he');
  ctx_ddl.add_stopword('"I_SPL"','her');
  ctx_ddl.add_stopword('"I_SPL"','here');
  ctx_ddl.add_stopword('"I_SPL"','hers');
  ctx_ddl.add_stopword('"I_SPL"','him');
  ctx_ddl.add_stopword('"I_SPL"','his');
  ctx_ddl.add_stopword('"I_SPL"','how');
  ctx_ddl.add_stopword('"I_SPL"','however');
  ctx_ddl.add_stopword('"I_SPL"','i');
  ctx_ddl.add_stopword('"I_SPL"','if');
  ctx_ddl.add_stopword('"I_SPL"','in');
  ctx_ddl.add_stopword('"I_SPL"','into');
  ctx_ddl.add_stopword('"I_SPL"','is');
  ctx_ddl.add_stopword('"I_SPL"','it');
  ctx_ddl.add_stopword('"I_SPL"','its');
  ctx_ddl.add_stopword('"I_SPL"','just');
  ctx_ddl.add_stopword('"I_SPL"','ll');
  ctx_ddl.add_stopword('"I_SPL"','me');
  ctx_ddl.add_stopword('"I_SPL"','might');
  ctx_ddl.add_stopword('"I_SPL"','my');
  ctx_ddl.add_stopword('"I_SPL"','no');
  ctx_ddl.add_stopword('"I_SPL"','non');
  ctx_ddl.add_stopword('"I_SPL"','nor');
  ctx_ddl.add_stopword('"I_SPL"','not');
  ctx_ddl.add_stopword('"I_SPL"','of');
  ctx_ddl.add_stopword('"I_SPL"','on');
  ctx_ddl.add_stopword('"I_SPL"','one');
  ctx_ddl.add_stopword('"I_SPL"','only');
  ctx_ddl.add_stopword('"I_SPL"','onto');
  ctx_ddl.add_stopword('"I_SPL"','or');
  ctx_ddl.add_stopword('"I_SPL"','our');
  ctx_ddl.add_stopword('"I_SPL"','ours');
  ctx_ddl.add_stopword('"I_SPL"','s');
  ctx_ddl.add_stopword('"I_SPL"','shall');
  ctx_ddl.add_stopword('"I_SPL"','she');
  ctx_ddl.add_stopword('"I_SPL"','should');
  ctx_ddl.add_stopword('"I_SPL"','since');
  ctx_ddl.add_stopword('"I_SPL"','so');
  ctx_ddl.add_stopword('"I_SPL"','some');
  ctx_ddl.add_stopword('"I_SPL"','still');
  ctx_ddl.add_stopword('"I_SPL"','such');
  ctx_ddl.add_stopword('"I_SPL"','t');
  ctx_ddl.add_stopword('"I_SPL"','than');
  ctx_ddl.add_stopword('"I_SPL"','that');
  ctx_ddl.add_stopword('"I_SPL"','the');
  ctx_ddl.add_stopword('"I_SPL"','their');
  ctx_ddl.add_stopword('"I_SPL"','them');
  ctx_ddl.add_stopword('"I_SPL"','then');
  ctx_ddl.add_stopword('"I_SPL"','there');
  ctx_ddl.add_stopword('"I_SPL"','therefore');
  ctx_ddl.add_stopword('"I_SPL"','these');
  ctx_ddl.add_stopword('"I_SPL"','they');
  ctx_ddl.add_stopword('"I_SPL"','this');
  ctx_ddl.add_stopword('"I_SPL"','those');
  ctx_ddl.add_stopword('"I_SPL"','though');
  ctx_ddl.add_stopword('"I_SPL"','through');
  ctx_ddl.add_stopword('"I_SPL"','thus');
  ctx_ddl.add_stopword('"I_SPL"','to');
  ctx_ddl.add_stopword('"I_SPL"','too');
  ctx_ddl.add_stopword('"I_SPL"','until');
  ctx_ddl.add_stopword('"I_SPL"','ve');
  ctx_ddl.add_stopword('"I_SPL"','very');
  ctx_ddl.add_stopword('"I_SPL"','was');
  ctx_ddl.add_stopword('"I_SPL"','we');
  ctx_ddl.add_stopword('"I_SPL"','were');
  ctx_ddl.add_stopword('"I_SPL"','what');
  ctx_ddl.add_stopword('"I_SPL"','when');
  ctx_ddl.add_stopword('"I_SPL"','where');
  ctx_ddl.add_stopword('"I_SPL"','whether');
  ctx_ddl.add_stopword('"I_SPL"','which');
  ctx_ddl.add_stopword('"I_SPL"','while');
  ctx_ddl.add_stopword('"I_SPL"','who');
  ctx_ddl.add_stopword('"I_SPL"','whose');
  ctx_ddl.add_stopword('"I_SPL"','why');
  ctx_ddl.add_stopword('"I_SPL"','will');
  ctx_ddl.add_stopword('"I_SPL"','with');
  ctx_ddl.add_stopword('"I_SPL"','would');
  ctx_ddl.add_stopword('"I_SPL"','yet');
  ctx_ddl.add_stopword('"I_SPL"','you');
  ctx_ddl.add_stopword('"I_SPL"','your');
  ctx_ddl.add_stopword('"I_SPL"','yours');
end;
/

begin
  ctx_ddl.create_preference('"I_STO"','BASIC_STORAGE');
  ctx_ddl.set_attribute('"I_STO"','R_TABLE_CLAUSE','lob (data) store as (cache)');
  ctx_ddl.set_attribute('"I_STO"','I_INDEX_CLAUSE','compress 2');
  ctx_ddl.set_attribute('"I_STO"','SMALL_R_ROW','YES');
end;
/


begin
  ctx_output.start_log('I_LOG');
end;
/

create index "TESTUSER"."I"
  on "TESTUSER"."T"
      ("C")
  indextype is ctxsys.context
  parameters('
    datastore       "I_DST"
    filter          "I_FIL"
    section group   "I_SGP"
    lexer           "I_LEX"
    wordlist        "I_WDL"
    stoplist        "I_SPL"
    storage         "I_STO"
  ')
/

begin
  ctx_output.end_log;
end;
/



Elapsed: 00:00:00.01
SQL> spool off
