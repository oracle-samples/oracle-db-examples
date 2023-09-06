set serveroutput on

exec ctx_ddl.drop_section_group('ot_sec_group')

begin
ctx_ddl.create_section_group('ot_sec_group', 'auto_section_group');
end;
/

drop table ot_profile_test;

create table ot_profile_test
(profile_id number,
query clob);

create index ot_profile_rule_ndx on ot_profile_test(query)
indextype is ctxsys.ctxrule parameters
('stoplist ctxsys.empty_stoplist
section group ot_sec_group');

insert into ot_profile_test values(1, '(apple and pears) and (1 within food)');
commit;

exec ctx_ddl.sync_index ('ot_profile_rule_ndx')

declare
a clob :=
	 '<table>
<fruits>apple orange pears banana</fruits>
<metadata>
<indicators>
<food>1</food>
</indicators>
</metadata>
</table>';
begin
for r in
	 (select profile_id
	  from	 ot_profile_test
	  where  matches (query, a) > 0
	  order  by profile_id)
loop
	 dbms_output.put_line (r.profile_id);
end loop;
end;
/ 

