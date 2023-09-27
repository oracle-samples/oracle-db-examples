exec ctx_thes.drop_thesaurus('tech')
exec ctx_thes.create_thesaurus('tech')
exec ctx_thes.create_synonym('tech', 'operating system')
exec ctx_thes.create_phrase ('tech', 'os');
exec ctx_thes.create_phrase ('tech', 'operating system', 'SYN', 'OS')
exec ctx_thes.create_phrase ('tech', 'operating'||chr(9)||'system', 'SYN', 'OS')
select ctx_thes.syn('os', 'tech') from dual;
