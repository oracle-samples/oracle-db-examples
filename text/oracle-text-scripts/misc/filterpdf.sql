-- this is an example of using the Oracle Text PL/SQL procedure
-- ctx_doc.policy_filter to filter a PDF file to plain text for indexing
-- or other purposes.

-- user needs "create any directory" priv and ctxapp role  to do this:

-- this is where our file resides
create directory MYDIR as 'c:\pdfdocs';

-- output table is purely so we have somewhere to put the plaintext CLOB
-- after we've filtered it

drop table output_table;
create table output_table( text clob );

-- drop and create the policy. The policy simply tells policy_filter that
-- it needs to use AUTO_FILTER (previously INSO_FILTER) for the document

exec ctx_ddl.drop_policy('myPolicy')

begin
   ctx_ddl.create_policy
      (policy_name   => 'myPolicy',
       filter        => 'ctxsys.auto_filter',
       section_group => null,
       lexer         => null,
       stoplist      => null,
       wordlist      => null
      );
end;
/

-- Now we'll create and run an anonymous PL/SQL block which filters a file
-- from a bfile and inserts the plain text output into output_table

-- We're using a BFILE here but it could just as easily use a BLOB if
-- the document is already in the database

declare 
   myBfile   bfile;
   outClob   clob;
begin

   myBfile := bfilename('MYDIR', 'newfeatures.pdf');

   ctx_doc.policy_filter
      (policy_name => 'myPolicy',
       document    => myBfile,
       restab      => outClob,
       plaintext   => TRUE
      );

   insert into output_table values ( outClob );

end;
/

-- Now fetch the first 500 chars of the plain text doc to prove it worked

set long 500

select * from output_table;
