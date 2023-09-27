set feedback 2

-- 1 German

prompt
prompt German query with accent
select text from test where contains(text, '
<query>
  <textquery lang="GERMAN">
    sh'||UNISTR('\00F6')||'n
  </textquery>
</query>') > 0;

prompt German query without accent
select text from test where contains(text, '
<query>
  <textquery lang="GERMAN">
    shon
  </textquery>
</query>') > 0;

prompt German query with alt form
select text from test where contains(text, '
<query>
  <textquery lang="GERMAN">
    shoen
  </textquery>
</query>') > 0;

set feedback off
