drop table t
/

CREATE TABLE t (id  VARCHAR2 (60), data clob)
/ 
 

INSERT ALL
    INTO t (id, data) VALUES ('Test_1', '<book title="Tale"> 
  		It was the best of times. 
</book> ')
    INTO t (id, data) VALUES ('Test_2', '<book title="Disclosure"> 
  		Opening times. 
</book>')
    INTO t (id, data) VALUES ('Test_3', '<book title="Blue"> 
  		No of times. 
</book> ')
    INTO t (id, data) VALUES ('Test_5', '<book title="Tale"> 
  		Times, times, times, times, times, times, times, times. 
</book> ')
    INTO t (id, data) VALUES ('Test_4', '<book title="Olympics"> 
  		It was the best of times.
</book> ')
    SELECT * FROM DUAL
/ 
 

BEGIN
     Ctx_Ddl.drop_Preference ('my_lexer');
END;
/ 

BEGIN
     Ctx_Ddl.Create_Preference ('my_lexer','BASIC_LEXER');
     Ctx_Ddl.Set_Attribute ( 'my_lexer', 'mixed_case', 'FALSE');
     Ctx_Ddl.Set_Attribute ( 'my_lexer', 'base_letter','TRUE');
END;
/ 

BEGIN
     Ctx_Ddl.drop_section_group ('myxmlgroup');
END;
   /

begin
     ctx_ddl.create_section_group('myxmlgroup', 'XML_SECTION_GROUP');
     ctx_ddl.add_zone_section('myxmlgroup', 'book', 'book');
     ctx_ddl.add_attr_section('myxmlgroup', 'booktitle', 'book@title');
end;
/
 
CREATE INDEX t_data_idx ON t (data) INDEXTYPE IS ctxsys.context
	PARAMETERS 
		('LEXER  my_lexer
             	datastore ctxsys.default_datastore 
             	filter ctxsys.null_filter 
             	section group myxmlgroup'
           	)
/

column id format a20
column title format a30

select id, xt.title, score(1)
from t, xmltable( '/book' PASSING XMLTYPE(t.data) 
                  COLUMNS title VARCHAR2(30) PATH '@title' 
                ) as xt 
where contains (data, '
   times ACCUM ( 
                (blue WITHIN booktitle)*5 OR
                (disclosure WITHIN booktitle)*4 OR
                (tale WITHIN booktitle)*3 
               )', 1) > 0
order by score(1) desc;

-- prog relax

select id, xt.title, score(1)
from t, xmltable( '/book' PASSING XMLTYPE(t.data) 
                  COLUMNS title VARCHAR2(30) PATH '@title' 
                ) as xt 
where contains (data, '
<query>
  <textquery>
    <progression>
      <seq>times AND (blue WITHIN booktitle)*10*10</seq>
      <seq>times AND (disclosure WITHIN booktitle)*10*10</seq>
      <seq>times AND (tale WITHIN booktitle)*10*10</seq>
      <seq>times</seq>
   </progression>
  </textquery>
</query>
', 1) > 0
order by score(1) desc;

