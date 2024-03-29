create or replace procedure p ( the_name in varchar2 )
is
 begin
   execute immediate
     'create or replace procedure ' || the_name          || chr(10) ||
     '  ( t in varchar2 )'                               || chr(10) ||
     'is'                                                || chr(10) ||
     'begin'                                             || chr(10) ||
     '  Dbms_Output.Put_Line ( t || t );'                || chr(10) ||
     'end;'                                              ;
 end p;
/

 
