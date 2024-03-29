begin
  ctx_ddl.create_preference('"GFDX_DOC_META_DST"','MULTI_COLUMN_DATASTORE');
  ctx_ddl.set_attribute('"GFDX_DOC_META_DST"','COLUMNS','lemplacement');
  ctx_ddl.set_attribute('"GFDX_DOC_META_DST"','FILTER','N');
end;
/

begin
  ctx_ddl.create_preference('"GFDX_DOC_META_FIL"','AUTO_FILTER');
  ctx_ddl.set_attribute('"GFDX_DOC_META_FIL"','TIMEOUT','120');
end;
/

begin
  ctx_ddl.create_section_group('"GFDX_DOC_META_SGP"','AUTO_SECTION_GROUP');
end;
/

begin
  ctx_ddl.create_preference('"GFDX_DOC_META_LEX"','MULTI_LEXER');
end;
/

begin
  ctx_ddl.create_preference('"GFDX_DOC_META_LBG"','BASIC_LEXER');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LBG"','PRINTJOINS','-/');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LBG"','BASE_LETTER','YES');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LBG"','INDEX_THEMES','NO');
end;
/

begin
  ctx_ddl.create_preference('"GFDX_DOC_META_LHR"','BASIC_LEXER');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LHR"','PRINTJOINS','-/');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LHR"','BASE_LETTER','YES');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LHR"','INDEX_THEMES','NO');
end;
/

begin
  ctx_ddl.create_preference('"GFDX_DOC_META_LCS"','BASIC_LEXER');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LCS"','PRINTJOINS','-/');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LCS"','BASE_LETTER','YES');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LCS"','INDEX_THEMES','NO');
end;
/

begin
  ctx_ddl.create_preference('"GFDX_DOC_META_LDK"','BASIC_LEXER');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LDK"','PRINTJOINS','-/');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LDK"','BASE_LETTER','YES');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LDK"','INDEX_THEMES','NO');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LDK"','ALTERNATE_SPELLING','DANISH');
end;
/

begin
  ctx_ddl.create_preference('"GFDX_DOC_META_L00"','BASIC_LEXER');
  ctx_ddl.set_attribute('"GFDX_DOC_META_L00"','PRINTJOINS','-/');
  ctx_ddl.set_attribute('"GFDX_DOC_META_L00"','BASE_LETTER','YES');
  ctx_ddl.set_attribute('"GFDX_DOC_META_L00"','INDEX_THEMES','NO');
end;
/

begin
  ctx_ddl.create_preference('"GFDX_DOC_META_LNL"','BASIC_LEXER');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LNL"','PRINTJOINS','-/');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LNL"','BASE_LETTER','YES');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LNL"','COMPOSITE','DUTCH');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LNL"','INDEX_THEMES','NO');
end;
/

begin
  ctx_ddl.create_preference('"GFDX_DOC_META_LGB"','BASIC_LEXER');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LGB"','PRINTJOINS','-/');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LGB"','BASE_LETTER','YES');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LGB"','INDEX_THEMES','NO');
end;
/

begin
  ctx_ddl.create_preference('"GFDX_DOC_META_LET"','BASIC_LEXER');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LET"','PRINTJOINS','-/');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LET"','BASE_LETTER','YES');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LET"','INDEX_THEMES','NO');
end;
/

begin
  ctx_ddl.create_preference('"GFDX_DOC_META_LSF"','BASIC_LEXER');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LSF"','PRINTJOINS','-/');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LSF"','BASE_LETTER','YES');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LSF"','INDEX_THEMES','NO');
end;
/

begin
  ctx_ddl.create_preference('"GFDX_DOC_META_LF"','BASIC_LEXER');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LF"','PRINTJOINS','-/');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LF"','BASE_LETTER','YES');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LF"','INDEX_THEMES','NO');
end;
/

begin
  ctx_ddl.create_preference('"GFDX_DOC_META_LD"','BASIC_LEXER');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LD"','PRINTJOINS','-/');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LD"','BASE_LETTER','YES');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LD"','COMPOSITE','GERMAN');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LD"','INDEX_THEMES','NO');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LD"','ALTERNATE_SPELLING','GERMAN');
end;
/

begin
  ctx_ddl.create_preference('"GFDX_DOC_META_LEL"','BASIC_LEXER');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LEL"','PRINTJOINS','-/');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LEL"','BASE_LETTER','YES');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LEL"','INDEX_THEMES','NO');
end;
/

begin
  ctx_ddl.create_preference('"GFDX_DOC_META_LHU"','BASIC_LEXER');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LHU"','PRINTJOINS','-/');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LHU"','BASE_LETTER','YES');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LHU"','INDEX_THEMES','NO');
end;
/

begin
  ctx_ddl.create_preference('"GFDX_DOC_META_LI"','BASIC_LEXER');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LI"','PRINTJOINS','-/');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LI"','BASE_LETTER','YES');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LI"','INDEX_THEMES','NO');
end;
/

begin
  ctx_ddl.create_preference('"GFDX_DOC_META_LLV"','BASIC_LEXER');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LLV"','PRINTJOINS','-/');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LLV"','BASE_LETTER','YES');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LLV"','INDEX_THEMES','NO');
end;
/

begin
  ctx_ddl.create_preference('"GFDX_DOC_META_LLT"','BASIC_LEXER');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LLT"','PRINTJOINS','-/');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LLT"','BASE_LETTER','YES');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LLT"','INDEX_THEMES','NO');
end;
/

begin
  ctx_ddl.create_preference('"GFDX_DOC_META_LN"','BASIC_LEXER');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LN"','PRINTJOINS','-/');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LN"','BASE_LETTER','YES');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LN"','INDEX_THEMES','NO');
end;
/

begin
  ctx_ddl.create_preference('"GFDX_DOC_META_LPL"','BASIC_LEXER');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LPL"','PRINTJOINS','-/');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LPL"','BASE_LETTER','YES');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LPL"','INDEX_THEMES','NO');
end;
/

begin
  ctx_ddl.create_preference('"GFDX_DOC_META_LPT"','BASIC_LEXER');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LPT"','PRINTJOINS','-/');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LPT"','BASE_LETTER','YES');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LPT"','INDEX_THEMES','NO');
end;
/

begin
  ctx_ddl.create_preference('"GFDX_DOC_META_LRO"','BASIC_LEXER');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LRO"','PRINTJOINS','-/');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LRO"','BASE_LETTER','YES');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LRO"','INDEX_THEMES','NO');
end;
/

begin
  ctx_ddl.create_preference('"GFDX_DOC_META_LSK"','BASIC_LEXER');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LSK"','PRINTJOINS','-/');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LSK"','BASE_LETTER','YES');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LSK"','INDEX_THEMES','NO');
end;
/

begin
  ctx_ddl.create_preference('"GFDX_DOC_META_LSL"','BASIC_LEXER');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LSL"','PRINTJOINS','-/');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LSL"','BASE_LETTER','YES');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LSL"','INDEX_THEMES','NO');
end;
/

begin
  ctx_ddl.create_preference('"GFDX_DOC_META_LE"','BASIC_LEXER');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LE"','PRINTJOINS','-/');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LE"','BASE_LETTER','YES');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LE"','INDEX_THEMES','NO');
end;
/

begin
  ctx_ddl.create_preference('"GFDX_DOC_META_LS"','BASIC_LEXER');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LS"','PRINTJOINS','-/');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LS"','BASE_LETTER','YES');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LS"','INDEX_THEMES','NO');
  ctx_ddl.set_attribute('"GFDX_DOC_META_LS"','ALTERNATE_SPELLING','SWEDISH');
end;
/

begin
  ctx_ddl.add_sub_lexer('"GFDX_DOC_META_LEX"','BULGARIAN','"GFDX_DOC_META_LBG"');
  ctx_ddl.add_sub_lexer('"GFDX_DOC_META_LEX"','CROATIAN','"GFDX_DOC_META_LHR"');
  ctx_ddl.add_sub_lexer('"GFDX_DOC_META_LEX"','CZECH','"GFDX_DOC_META_LCS"','MT');
  ctx_ddl.add_sub_lexer('"GFDX_DOC_META_LEX"','DANISH','"GFDX_DOC_META_LDK"','DA');
  ctx_ddl.add_sub_lexer('"GFDX_DOC_META_LEX"','DEFAULT','"GFDX_DOC_META_L00"');
  ctx_ddl.add_sub_lexer('"GFDX_DOC_META_LEX"','DUTCH','"GFDX_DOC_META_LNL"');
  ctx_ddl.add_sub_lexer('"GFDX_DOC_META_LEX"','ENGLISH','"GFDX_DOC_META_LGB"','EN');
  ctx_ddl.add_sub_lexer('"GFDX_DOC_META_LEX"','ESTONIAN','"GFDX_DOC_META_LET"');
  ctx_ddl.add_sub_lexer('"GFDX_DOC_META_LEX"','FINNISH','"GFDX_DOC_META_LSF"','FI');
  ctx_ddl.add_sub_lexer('"GFDX_DOC_META_LEX"','FRENCH','"GFDX_DOC_META_LF"','FR');
  ctx_ddl.add_sub_lexer('"GFDX_DOC_META_LEX"','GERMAN','"GFDX_DOC_META_LD"','DE');
  ctx_ddl.add_sub_lexer('"GFDX_DOC_META_LEX"','GREEK','"GFDX_DOC_META_LEL"');
  ctx_ddl.add_sub_lexer('"GFDX_DOC_META_LEX"','HUNGARIAN','"GFDX_DOC_META_LHU"');
  ctx_ddl.add_sub_lexer('"GFDX_DOC_META_LEX"','ITALIAN','"GFDX_DOC_META_LI"','IT');
  ctx_ddl.add_sub_lexer('"GFDX_DOC_META_LEX"','LATVIAN','"GFDX_DOC_META_LLV"');
  ctx_ddl.add_sub_lexer('"GFDX_DOC_META_LEX"','LITHUANIAN','"GFDX_DOC_META_LLT"');
  ctx_ddl.add_sub_lexer('"GFDX_DOC_META_LEX"','NORWEGIAN','"GFDX_DOC_META_LN"','NO');
  ctx_ddl.add_sub_lexer('"GFDX_DOC_META_LEX"','POLISH','"GFDX_DOC_META_LPL"');
  ctx_ddl.add_sub_lexer('"GFDX_DOC_META_LEX"','PORTUGUESE','"GFDX_DOC_META_LPT"');
  ctx_ddl.add_sub_lexer('"GFDX_DOC_META_LEX"','ROMANIAN','"GFDX_DOC_META_LRO"');
  ctx_ddl.add_sub_lexer('"GFDX_DOC_META_LEX"','SLOVAK','"GFDX_DOC_META_LSK"');
  ctx_ddl.add_sub_lexer('"GFDX_DOC_META_LEX"','SLOVENIAN','"GFDX_DOC_META_LSL"');
  ctx_ddl.add_sub_lexer('"GFDX_DOC_META_LEX"','SPANISH','"GFDX_DOC_META_LE"','ES');
  ctx_ddl.add_sub_lexer('"GFDX_DOC_META_LEX"','SWEDISH','"GFDX_DOC_META_LS"','SV');
end;
/

begin
  ctx_ddl.create_preference('"GFDX_DOC_META_WDL"','BASIC_WORDLIST');
  ctx_ddl.set_attribute('"GFDX_DOC_META_WDL"','STEMMER','AUTO');
  ctx_ddl.set_attribute('"GFDX_DOC_META_WDL"','FUZZY_MATCH','AUTO');
end;
/

begin
  ctx_ddl.create_preference('"GFDX_DOC_META_STO"','BASIC_STORAGE');
  ctx_ddl.set_attribute('"GFDX_DOC_META_STO"','R_TABLE_CLAUSE','lob (data) store as lobpr (cache)');
  ctx_ddl.set_attribute('"GFDX_DOC_META_STO"','I_INDEX_CLAUSE','compress 2');
end;
/

begin
  ctx_ddl.create_preference('"GFDX_DOC_META_S0001"','BASIC_STORAGE');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0001"','I_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0001"','K_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0001"','R_TABLE_CLAUSE','lob(data) store as lob1 (cache) tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0001"','N_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0001"','I_INDEX_CLAUSE','compress 2 tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0001"','P_TABLE_CLAUSE','tablespace USERS NOLOGGING');
end;
/

begin
  ctx_ddl.create_preference('"GFDX_DOC_META_S0002"','BASIC_STORAGE');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0002"','I_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0002"','K_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0002"','R_TABLE_CLAUSE','lob(data) store as lob2 (cache) tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0002"','N_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0002"','I_INDEX_CLAUSE','compress 2 tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0002"','P_TABLE_CLAUSE','tablespace USERS NOLOGGING');
end;
/

begin
  ctx_ddl.create_preference('"GFDX_DOC_META_S0003"','BASIC_STORAGE');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0003"','I_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0003"','K_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0003"','R_TABLE_CLAUSE','lob(data) store as lob3 (cache) tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0003"','N_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0003"','I_INDEX_CLAUSE','compress 2 tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0003"','P_TABLE_CLAUSE','tablespace USERS NOLOGGING');
end;
/

begin
  ctx_ddl.create_preference('"GFDX_DOC_META_S0004"','BASIC_STORAGE');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0004"','I_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0004"','K_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0004"','R_TABLE_CLAUSE','lob(data) store as lob4 (cache) tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0004"','N_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0004"','I_INDEX_CLAUSE','compress 2 tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0004"','P_TABLE_CLAUSE','tablespace USERS NOLOGGING');
end;
/

begin
  ctx_ddl.create_preference('"GFDX_DOC_META_S0005"','BASIC_STORAGE');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0005"','I_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0005"','K_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0005"','R_TABLE_CLAUSE','lob(data) store as lob5 (cache) tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0005"','N_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0005"','I_INDEX_CLAUSE','compress 2 tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0005"','P_TABLE_CLAUSE','tablespace USERS NOLOGGING');
end;
/

begin
  ctx_ddl.create_preference('"GFDX_DOC_META_S0006"','BASIC_STORAGE');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0006"','I_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0006"','K_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0006"','R_TABLE_CLAUSE','lob(data) store as lob6 (cache) tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0006"','N_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0006"','I_INDEX_CLAUSE','compress 2 tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0006"','P_TABLE_CLAUSE','tablespace USERS NOLOGGING');
end;
/

begin
  ctx_ddl.create_preference('"GFDX_DOC_META_S0007"','BASIC_STORAGE');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0007"','I_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0007"','K_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0007"','R_TABLE_CLAUSE','lob(data) store as lob7 (cache) tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0007"','N_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0007"','I_INDEX_CLAUSE','compress 2 tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0007"','P_TABLE_CLAUSE','tablespace USERS NOLOGGING');
end;
/

begin
  ctx_ddl.create_preference('"GFDX_DOC_META_S0008"','BASIC_STORAGE');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0008"','I_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0008"','K_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0008"','R_TABLE_CLAUSE','lob(data) store as lob8 (cache) tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0008"','N_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0008"','I_INDEX_CLAUSE','compress 2 tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0008"','P_TABLE_CLAUSE','tablespace USERS NOLOGGING');
end;
/

begin
  ctx_ddl.create_preference('"GFDX_DOC_META_S0009"','BASIC_STORAGE');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0009"','I_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0009"','K_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0009"','R_TABLE_CLAUSE','lob(data) store as lob9 (cache) tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0009"','N_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0009"','I_INDEX_CLAUSE','compress 2 tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0009"','P_TABLE_CLAUSE','tablespace USERS NOLOGGING');
end;
/

begin
  ctx_ddl.create_preference('"GFDX_DOC_META_S0010"','BASIC_STORAGE');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0010"','I_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0010"','K_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0010"','R_TABLE_CLAUSE','lob(data) store as lob10 (cache) tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0010"','N_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0010"','I_INDEX_CLAUSE','compress 2 tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0010"','P_TABLE_CLAUSE','tablespace USERS NOLOGGING');
end;
/

begin
  ctx_ddl.create_preference('"GFDX_DOC_META_S0011"','BASIC_STORAGE');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0011"','I_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0011"','K_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0011"','R_TABLE_CLAUSE','lob(data) store as lob11 (cache) tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0011"','N_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0011"','I_INDEX_CLAUSE','compress 2 tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0011"','P_TABLE_CLAUSE','tablespace USERS NOLOGGING');
end;
/

begin
  ctx_ddl.create_preference('"GFDX_DOC_META_S0012"','BASIC_STORAGE');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0012"','I_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0012"','K_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0012"','R_TABLE_CLAUSE','lob(data) store as lob12 (cache) tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0012"','N_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0012"','I_INDEX_CLAUSE','compress 2 tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0012"','P_TABLE_CLAUSE','tablespace USERS NOLOGGING');
end;
/

begin
  ctx_ddl.create_preference('"GFDX_DOC_META_S0013"','BASIC_STORAGE');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0013"','I_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0013"','K_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0013"','R_TABLE_CLAUSE','lob(data) store as lob13 (cache) tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0013"','N_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0013"','I_INDEX_CLAUSE','compress 2 tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0013"','P_TABLE_CLAUSE','tablespace USERS NOLOGGING');
end;
/

begin
  ctx_ddl.create_preference('"GFDX_DOC_META_S0014"','BASIC_STORAGE');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0014"','I_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0014"','K_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0014"','R_TABLE_CLAUSE','lob(data) store as lob14 (cache) tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0014"','N_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0014"','I_INDEX_CLAUSE','compress 2 tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0014"','P_TABLE_CLAUSE','tablespace USERS NOLOGGING');
end;
/

begin
  ctx_ddl.create_preference('"GFDX_DOC_META_S0015"','BASIC_STORAGE');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0015"','I_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0015"','K_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0015"','R_TABLE_CLAUSE','lob(data) store as lob15 (cache) tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0015"','N_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0015"','I_INDEX_CLAUSE','compress 2 tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0015"','P_TABLE_CLAUSE','tablespace USERS NOLOGGING');
end;
/

begin
  ctx_ddl.create_preference('"GFDX_DOC_META_S0016"','BASIC_STORAGE');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0016"','I_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0016"','K_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0016"','R_TABLE_CLAUSE','lob(data) store as lob16 (cache) tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0016"','N_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0016"','I_INDEX_CLAUSE','compress 2 tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0016"','P_TABLE_CLAUSE','tablespace USERS NOLOGGING');
end;
/

begin
  ctx_ddl.create_preference('"GFDX_DOC_META_S0017"','BASIC_STORAGE');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0017"','I_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0017"','K_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0017"','R_TABLE_CLAUSE','lob(data) store as lob17 (cache) tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0017"','N_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0017"','I_INDEX_CLAUSE','compress 2 tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0017"','P_TABLE_CLAUSE','tablespace USERS NOLOGGING');
end;
/

begin
  ctx_ddl.create_preference('"GFDX_DOC_META_S0018"','BASIC_STORAGE');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0018"','I_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0018"','K_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0018"','R_TABLE_CLAUSE','lob(data) store as lob18 (cache) tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0018"','N_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0018"','I_INDEX_CLAUSE','compress 2 tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0018"','P_TABLE_CLAUSE','tablespace USERS NOLOGGING');
end;
/

begin
  ctx_ddl.create_preference('"GFDX_DOC_META_S0019"','BASIC_STORAGE');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0019"','I_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0019"','K_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0019"','R_TABLE_CLAUSE','lob(data) store as lob19 (cache) tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0019"','N_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0019"','I_INDEX_CLAUSE','compress 2 tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0019"','P_TABLE_CLAUSE','tablespace USERS NOLOGGING');
end;
/

begin
  ctx_ddl.create_preference('"GFDX_DOC_META_S0020"','BASIC_STORAGE');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0020"','I_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0020"','K_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0020"','R_TABLE_CLAUSE','lob(data) store as lob20 (cache) tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0020"','N_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0020"','I_INDEX_CLAUSE','compress 2 tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0020"','P_TABLE_CLAUSE','tablespace USERS NOLOGGING');
end;
/

begin
  ctx_ddl.create_preference('"GFDX_DOC_META_S0021"','BASIC_STORAGE');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0021"','I_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0021"','K_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0021"','R_TABLE_CLAUSE','lob(data) store as lob21 (cache) tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0021"','N_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0021"','I_INDEX_CLAUSE','compress 2 tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0021"','P_TABLE_CLAUSE','tablespace USERS NOLOGGING');
end;
/

begin
  ctx_ddl.create_preference('"GFDX_DOC_META_S0022"','BASIC_STORAGE');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0022"','I_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0022"','K_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0022"','R_TABLE_CLAUSE','lob(data) store as lob22 (cache) tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0022"','N_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0022"','I_INDEX_CLAUSE','compress 2 tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0022"','P_TABLE_CLAUSE','tablespace USERS NOLOGGING');
end;
/

begin
  ctx_ddl.create_preference('"GFDX_DOC_META_S0023"','BASIC_STORAGE');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0023"','I_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0023"','K_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0023"','R_TABLE_CLAUSE','lob(data) store as lob23 (cache) tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0023"','N_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0023"','I_INDEX_CLAUSE','compress 2 tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0023"','P_TABLE_CLAUSE','tablespace USERS NOLOGGING');
end;
/

begin
  ctx_ddl.create_preference('"GFDX_DOC_META_S0024"','BASIC_STORAGE');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0024"','I_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0024"','K_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0024"','R_TABLE_CLAUSE','lob(data) store as lob24 (cache) tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0024"','N_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0024"','I_INDEX_CLAUSE','compress 2 tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0024"','P_TABLE_CLAUSE','tablespace USERS NOLOGGING');
end;
/

begin
  ctx_ddl.create_preference('"GFDX_DOC_META_S0025"','BASIC_STORAGE');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0025"','I_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0025"','K_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0025"','R_TABLE_CLAUSE','lob(data) store as lob25 (cache) tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0025"','N_TABLE_CLAUSE','tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0025"','I_INDEX_CLAUSE','compress 2 tablespace USERS NOLOGGING');
  ctx_ddl.set_attribute('"GFDX_DOC_META_S0025"','P_TABLE_CLAUSE','tablespace USERS NOLOGGING');
end;
/
