-- turn all tags into simple words
-- except for FIELDS, BODYTEXT and DOCUMENT

create or replace package sectionutils as
   function cleanup_sections( doc in clob ) return clob;
end sectionutils;
/

create or replace package body sectionutils as
   function cleanup_sections( doc in clob ) return clob is
      type sectionlist is varray(10) of varchar2(30);
      sections sectionlist;
      work clob;
   begin
      sections := sectionlist('FIELDS', 'BODYTEXT', 'DOCUMENT');

      work := doc;

      for i in sections.FIRST .. sections.LAST loop
         work := replace( work, '<' ||sections(i)||'>', '(*$'||sections(i)||'$*)' );
         work := replace( work, '</'||sections(i)||'>', '(*$/'||sections(i)||'$*)' );
      end loop;

      work := replace( work, '<', ' ' );
      work := replace( work, '>', ' ' );
      work := replace( work, '(*$', '<' );
      work := replace( work, '$*)', '>' );

   return work;
   end;
  
end sectionutils;
/


list 
show errors

-- test:

select sectionutils.cleanup_sections('the <BODYTEXT>quick <brown> <foo>fox</foo> bar </BODYTEXT> <FIELDS>foo</FIELDS>') from dual;


   
