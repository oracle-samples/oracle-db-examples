drop table test_sh4;

create table test_sh4 (text1 clob,text2 clob,text3 clob);
 
insert into test_sh4 values ('kit tan cool card blue', null, null);

exec ctx_ddl.drop_preference('test_mcd')
exec ctx_ddl.drop_preference('test_lex1')
exec ctx_ddl.drop_section_group('test_sg')
exec ctx_ddl.drop_preference('substring_pref')
exec ctx_ddl.drop_preference('textstore')

begin
   ctx_ddl.create_preference ('test_mcd', 'multi_column_datastore'); -- utilizing the same index for multiple columns
    ctx_ddl.set_attribute
      ('test_mcd',
       'columns',
       'replace (text1, '' '', '''') nd1, -- virtual column to eliminate white spaces in text1 column 
        text1 text1,  
        replace (text2, '' '', '''') nd2,  -- virtual column to eliminate white spaces in text2 column 
        text2 text2');
    ctx_ddl.create_preference ('test_lex1', 'basic_lexer');
    ctx_ddl.set_attribute ('test_lex1', 'whitespace', '/\|-_+&'); --translating special characters as white space using lexer
    ctx_ddl.create_section_group ('test_sg', 'basic_section_group'); -- creating section group to search within sections.
    ctx_ddl.add_field_section ('test_sg', 'text1', 'text1', true);
    ctx_ddl.add_field_section ('test_sg', 'nd1', 'nd1', true);
    ctx_ddl.add_field_section ('test_sg', 'text2', 'text2', true);
    ctx_ddl.add_field_section ('test_sg', 'nd2', 'nd2', true);
	ctx_ddl.create_preference('SUBSTRING_PREF', 'BASIC_WORDLIST');
    ctx_ddl.set_attribute('SUBSTRING_PREF','SUBSTRING_INDEX','TRUE');
	ctx_ddl.set_attribute('SUBSTRING_PREF','PREFIX_INDEX','TRUE');
	ctx_ddl.set_attribute('SUBSTRING_PREF','PREFIX_MIN_LENGTH', '3');
	ctx_ddl.set_attribute('SUBSTRING_PREF','PREFIX_MAX_LENGTH', '8');
	ctx_ddl.create_preference('textstore', 'BASIC_STORAGE');
    ctx_ddl.set_attribute('textstore', 'I_TABLE_CLAUSE','tablespace USERS storage (initial 64K)');
    ctx_ddl.set_attribute('textstore', 'K_TABLE_CLAUSE','tablespace USERS storage (initial 64K)');
    ctx_ddl.set_attribute('textstore', 'R_TABLE_CLAUSE','tablespace USERS storage (initial 64K)');
    ctx_ddl.set_attribute('textstore', 'N_TABLE_CLAUSE','tablespace USERS storage (initial 64K)');
    ctx_ddl.set_attribute('textstore', 'I_INDEX_CLAUSE','tablespace USERS storage (initial 64K)');
    ctx_ddl.set_attribute('textstore', 'P_TABLE_CLAUSE','tablespace USERS storage (initial 64K)');
end;
/ 
 
create index IX_test_sh4  on test_sh4 (text3) 
indextype is ctxsys.context
parameters
    ('datastore test_mcd
      lexer          test_lex1
      section group  test_sg  
	  wordlist SUBSTRING_PREF MEMORY 50M 
	  SYNC ( ON COMMIT)
	  storage textstore'
	  );

set serveroutput on size unlimited;

variable ProgRelaxationXML  clob;

begin
 :ProgRelaxationXML := '<query><textquery><progression><seq>{KIT TAN COOL CARD BLUE} within text1</seq><seq>{KITTANCOOLCARDBLUE} within nd1</seq><seq>{KIT TAN COOL CARD BLUE} within text2</seq><seq>{KITTANCOOLCARDBLUE} within nd2</seq><seq>((KIT% and TAN% and COOL% and CARD% and BLUE%)) within text1</seq><seq>((KIT% and TAN% and COOL% and CARD% and BLUE%)) within text2</seq><seq>((KIT% and TAN% and COOL% and CARD%) or (KIT% and TAN% and CARD% and BLUE%) or (KIT% and COOL% and CARD% and BLUE%) or (TAN%'||'
 and COOL% and CARD% and BLUE%) or (KIT% and TAN% and COOL% and BLUE%)) within text1</seq><seq>((KIT% and TAN% and COOL% and CARD%) or (KIT% and TAN% and CARD% and BLUE%) or (KIT% and COOL% and CARD% and BLUE%) or (TAN% and COOL% and CARD% and BLUE%) or (KIT% and TAN% and COOL% and BLUE%)) within text2</seq><seq>((KIT% and TAN% and COOL%) or (TAN% and COOL% and CARD%) or (KIT% and TAN% and CARD%) or (COOL% and CARD% and BLUE%) or (TAN% and CARD% and BLUE%) or (TAN% and COOL% and BLUE%) or (KIT% and CARD% '||'
and BLUE%) or (KIT% and COOL% and BLUE%) or (KIT% and TAN% and BLUE%) or (KIT% and COOL% and CARD%)) within text1</seq><seq>((KIT% and TAN% and COOL%) or (TAN% and COOL% and CARD%) or (KIT% and TAN% and CARD%) or (COOL% and CARD% and BLUE%) or (TAN% and CARD% and BLUE%) or (TAN% and COOL% and BLUE%) or (KIT% and CARD% and BLUE%) or (KIT% and COOL% and BLUE%) or (KIT% and TAN% and BLUE%) or (KIT% and COOL% and CARD%)) within text2</seq><seq>((CARD% and BLUE%) or (COOL% and BLUE%) or (TAN% and COOL%) or (KIT% and TAN%) '||'
or (COOL% and CARD%) or (KIT% and COOL%) or (KIT% and CARD%) or (TAN% and CARD%) or (KIT% and BLUE%) or (TAN% and BLUE%)) within text1</seq><seq>((CARD% and BLUE%) or (COOL% and BLUE%) or (TAN% and COOL%) or (KIT% and TAN%) or (COOL% and CARD%) or (KIT% and COOL%) or (KIT% and CARD%) or (TAN% and CARD%) or (KIT% and BLUE%) or (TAN% and BLUE%)) within text2</seq><seq>((KIT% , TAN% , COOL% , CARD% , BLUE%)) within text1</seq><seq>((KIT% , TAN% , COOL% , CARD% , BLUE%)) within text2</seq><seq>((!KIT and !TAN '||'
and !COOL and !CARD and !BLUE)) within text1</seq><seq>((!KIT and !TAN and !COOL and !CARD and !BLUE)) within text2</seq><seq>((!KIT and !TAN and !COOL and !CARD) or (!KIT and !TAN and !CARD and !BLUE) or (!KIT and !COOL and !CARD and !BLUE) or (!TAN and !COOL and !CARD and !BLUE) or (!KIT and !TAN and !COOL and !BLUE)) within text1</seq><seq>((!KIT and !TAN and !COOL and !CARD) or (!KIT and !TAN and !CARD and !BLUE) or (!KIT and !COOL and !CARD and !BLUE) or (!TAN and !COOL and !CARD and !BLUE) or (!KIT '||'
and !TAN and !COOL and !BLUE)) within text2</seq><seq>((!KIT and !TAN and !COOL) or (!TAN and !COOL and !CARD) or (!KIT and !TAN and !CARD) or (!COOL and !CARD and !BLUE) or (!TAN and !CARD and !BLUE) or (!TAN and !COOL and !BLUE) or (!KIT and !CARD and !BLUE) or (!KIT and !COOL and !BLUE) or (!KIT and !TAN and !BLUE) or (!KIT and !COOL and !CARD)) within text1</seq><seq>((!KIT and !TAN and !COOL) or (!TAN and !COOL and !CARD) or (!KIT and !TAN and !CARD) or (!COOL and !CARD and !BLUE) or (!TAN and !CARD '||'
and !BLUE) or (!TAN and !COOL and !BLUE) or (!KIT and !CARD and !BLUE) or (!KIT and !COOL and !BLUE) or (!KIT and !TAN and !BLUE) or (!KIT and !COOL and !CARD)) within text2</seq><seq>((!CARD and !BLUE) or (!COOL and !BLUE) or (!TAN and !COOL) or (!KIT and !TAN) or (!COOL and !CARD) or (!KIT and !COOL) or (!KIT and !CARD) or (!TAN and !CARD) or (!KIT and !BLUE) or (!TAN and !BLUE)) within text1</seq><seq>((!CARD and !BLUE) or (!COOL and !BLUE) or (!TAN and !COOL) or (!KIT and !TAN) or (!COOL and !CARD) or '||'
(!KIT and !COOL) or (!KIT and !CARD) or (!TAN and !CARD) or (!KIT and !BLUE) or (!TAN and !BLUE)) within text2</seq><seq>((!KIT , !TAN , !COOL , !CARD , !BLUE)) within text1</seq><seq>((!KIT , !TAN , !COOL , !CARD , !BLUE)) within text2</seq><seq>((?KIT and ?TAN and ?COOL and ?CARD and ?BLUE)) within text1</seq><seq>((?KIT and ?TAN and ?COOL and ?CARD and ?BLUE)) within text2</seq><seq>((?KIT and ?TAN and ?COOL and ?CARD) or (?KIT and ?TAN and ?CARD and ?BLUE) or (?KIT and ?COOL and ?CARD and ?BLUE) or (?TAN 
'||'
and ?COOL and ?CARD and ?BLUE) or (?KIT and ?TAN and ?COOL and ?BLUE)) within text1</seq><seq>((?KIT and ?TAN and ?COOL and ?CARD) or (?KIT and ?TAN and ?CARD and ?BLUE) or (?KIT and ?COOL and ?CARD and ?BLUE) or (?TAN and ?COOL and ?CARD and ?BLUE) or (?KIT and ?TAN and ?COOL and ?BLUE)) within text2</seq><seq>((?KIT and ?TAN and ?COOL) or (?TAN and ?COOL and ?CARD) or (?KIT and ?TAN and ?CARD) or (?COOL and ?CARD and ?BLUE) or (?TAN and ?CARD and ?BLUE) or (?TAN and ?COOL and ?BLUE) or (?KIT and ?CARD and '||'
?BLUE) or (?KIT and ?COOL and ?BLUE) or (?KIT and ?TAN and ?BLUE) or (?KIT and ?COOL and ?CARD)) within text1</seq><seq>((?KIT and ?TAN and ?COOL) or (?TAN and ?COOL and ?CARD) or (?KIT and ?TAN and ?CARD) or (?COOL and ?CARD and ?BLUE) or (?TAN and ?CARD and ?BLUE) or (?TAN and ?COOL and ?BLUE) or (?KIT and ?CARD and ?BLUE) or (?KIT and ?COOL and ?BLUE) or (?KIT and ?TAN and ?BLUE) or (?KIT and ?COOL and ?CARD)) within text2</seq><seq>((?CARD and ?BLUE) or (?COOL and ?BLUE) or (?TAN and ?COOL) or (?KIT and '||'
?TAN) or (?COOL and ?CARD) or (?KIT and ?COOL) or (?KIT and ?CARD) or (?TAN and ?CARD) or (?KIT and ?BLUE) or (?TAN and ?BLUE)) within text1</seq><seq>((?CARD and ?BLUE) or (?COOL and ?BLUE) or (?TAN and ?COOL) or (?KIT and ?TAN) or (?COOL and ?CARD) or (?KIT and ?COOL) or (?KIT and ?CARD) or (?TAN and ?CARD) or (?KIT and ?BLUE) or (?TAN and '||'
?BLUE)) within text2</seq><seq>((?KIT , ?TAN , ?COOL , ?CARD , ?BLUE)) within text1</seq><seq>((?KIT , ?TAN , ?COOL , ?CARD , ?BLUE)) within text2</seq></progression></textquery><score datatype="FLOAT" algorithm="default"/></query>';
end;
/

SELECT SCORE(1) score,t.* FROM test_sh4 t 
WHERE CONTAINS (text3,  :ProgRelaxationXML ,1) > 1 
order by score desc;