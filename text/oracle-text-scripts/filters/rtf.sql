connect roger/roger

drop directory foo;

create directory foo as 'h:\temp\';


drop table t;
drop table results;

create table results (text clob, chartext varchar2(2000) );

create table t (id number primary key, text bfile);
insert into t values( 1, bfilename('FOO', '0500236.rtf') );

exec ctx_ddl.drop_policy( 'mypol' );
exec ctx_ddl.create_policy( 'mypol', 'ctxsys.auto_filter' )

set long 50000

exec ctx_doc.set_key_type('primary_key')

declare 
  mybfile bfile;
  myblob blob;
  myclob clob;
  buff   varchar2(2000);
  amt    number := 100;
begin
  select text into mybfile from t;
  dbms_lob.createtemporary( myblob, true );
  dbms_lob.open( mybfile, dbms_lob.file_readonly );
  dbms_lob.loadfromfile( myblob, mybfile , dbms_lob.getlength( mybfile ) );

  dbms_lob.createtemporary( myclob, true );
  ctx_doc.policy_filter( 'mypol', mybfile, myclob, FALSE, 'EN', 'BINARY', 'UTF16');
 
  dbms_lob.open( myclob, dbms_lob.lob_readonly );
  dbms_lob.read (myclob, amt, 1, buff );

  insert into results values (myclob, buff);

  dbms_lob.close( mybfile );
  dbms_lob.close( myclob );
  dbms_lob.freetemporary( myblob );
end;
/

select dump(chartext) from results;




