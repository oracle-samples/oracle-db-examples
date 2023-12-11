
create table gfd_format_version_physique (lemplacement varchar2(2000), pkey number, vcodelangue varchar2(20) )
partition by range (pkey)
( partition BG values less than  (  1 ),
  partition CS values less than  (  2 ),
  partition DA values less than  (  3 ),
  partition DE values less than  (  4 ),
  partition EL values less than  (  5 ),
  partition EN values less than  (  6 ),
  partition ES values less than  (  7 ),
  partition ET values less than  (  8 ),
  partition FI values less than  (  9 ),
  partition FR values less than  ( 10 ),
  partition GA values less than  ( 11 ),
  partition HR values less than  ( 12 ),
  partition HU values less than  ( 13 ),
  partition IT values less than  ( 14 ),
  partition LT values less than  ( 15 ),
  partition LV values less than  ( 16 ),
  partition MT values less than  ( 17 ),
  partition NL values less than  ( 18 ),
  partition NO values less than  ( 19 ),
  partition PL values less than  ( 20 ),
  partition PT values less than  ( 21 ),
  partition RO values less than  ( 22 ),
  partition SK values less than  ( 23 ),
  partition SL values less than  ( 24 ),
  partition SV values less than  ( maxvalue )
);

begin
  ctx_output.start_log('GFDX_DOC_META_LOG');
end;
/

create index "GFDX_DOC_META"
  on "GFD_FORMAT_VERSION_PHYSIQUE"
      ("LEMPLACEMENT")
  indextype is ctxsys.context
  parameters('
    datastore       "GFDX_DOC_META_DST"
    filter          "GFDX_DOC_META_FIL"
    section group   "GFDX_DOC_META_SGP"
    lexer           "GFDX_DOC_META_LEX"
    wordlist        "GFDX_DOC_META_WDL"
    storage         "GFDX_DOC_META_STO"
    language column "VCODELANGUE"
  ')
  local (
    partition BG
      parameters ('storage "GFDX_DOC_META_S0001"'),
    partition CS
      parameters ('storage "GFDX_DOC_META_S0002"'),
    partition DA
      parameters ('storage "GFDX_DOC_META_S0003"'),
    partition DE
      parameters ('storage "GFDX_DOC_META_S0004"'),
    partition EL
      parameters ('storage "GFDX_DOC_META_S0005"'),
    partition EN
      parameters ('storage "GFDX_DOC_META_S0006"'),
    partition ES
      parameters ('storage "GFDX_DOC_META_S0007"'),
    partition ET
      parameters ('storage "GFDX_DOC_META_S0008"'),
    partition FI
      parameters ('storage "GFDX_DOC_META_S0009"'),
    partition FR
      parameters ('storage "GFDX_DOC_META_S0010"'),
    partition GA
      parameters ('storage "GFDX_DOC_META_S0011"'),
    partition HR
      parameters ('storage "GFDX_DOC_META_S0012"'),
    partition HU
      parameters ('storage "GFDX_DOC_META_S0013"'),
    partition IT
      parameters ('storage "GFDX_DOC_META_S0014"'),
    partition LT
      parameters ('storage "GFDX_DOC_META_S0015"'),
    partition LV
      parameters ('storage "GFDX_DOC_META_S0016"'),
    partition MT
      parameters ('storage "GFDX_DOC_META_S0017"'),
    partition NL
      parameters ('storage "GFDX_DOC_META_S0018"'),
    partition NO
      parameters ('storage "GFDX_DOC_META_S0019"'),
    partition PL
      parameters ('storage "GFDX_DOC_META_S0020"'),
    partition PT
      parameters ('storage "GFDX_DOC_META_S0021"'),
    partition RO
      parameters ('storage "GFDX_DOC_META_S0022"'),
    partition SK
      parameters ('storage "GFDX_DOC_META_S0023"'),
    partition SL
      parameters ('storage "GFDX_DOC_META_S0024"'),
    partition SV
      parameters ('storage "GFDX_DOC_META_S0025"')
  )
/

begin
  ctx_output.end_log;
end;
/

