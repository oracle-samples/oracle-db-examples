alter session set events '30579 trace name context forever, level 4096';


set serverout on size 1000000

exec ctx_ddl.drop_policy('mypol')
ctx_ddl.drop_preference('mylexer')

begin 
   ctx_ddl.create_preference('mylexer', 'auto_lexer');
end;
/

begin
   ctx_ddl.create_policy(
      policy_name=>'mypol',
      lexer=>'mylexer');
end;
/

declare
   line varchar2(64);
   mkclob clob;
   resulttable ctx_doc.language_tab;
begin
   line := 'mypol';
   mkclob := 'Regjeringen vil gjennomføre en rekke tiltak for å få ned utslippene av klimagasser og skape teknologiutvikling. Noen av de viktigste tiltakene er et nytt klima- og energifond, økt CO2-avgift på sokkelen og satsing på kollektivtrafikk.';

   mkclob := 'testing a new document';

   ctx_doc.policy_languages(policy_name=>line, document=>mkclob, restab=>resulttable);

   for i in resulttable.first .. resulttable.last loop
      dbms_output.put_line( resulttable(i).language || ' ' || resulttable(i).score);
   end loop;
end;
/
