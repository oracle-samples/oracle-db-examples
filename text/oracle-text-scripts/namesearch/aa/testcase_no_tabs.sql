spool testcase_no_tabs.log

exec ctx_thes.drop_thesaurus('nicknames')

host ctxload -user roger/roger -name nicknames -thes -file nicknames_no_tabs.txt -thescase n

-- with tab chars you will not see 'OSSY' in this output:
select ctx_thes.syn('oswald', 'nicknames') from dual;

-- with tab characters there will be no synonyms for PAMELA
select ctx_thes.syn('pamela', 'nicknames') from dual;

spool off
