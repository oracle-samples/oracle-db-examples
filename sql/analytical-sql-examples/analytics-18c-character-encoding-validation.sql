REM   Script: 18c character encoding validation
REM   New routines in UTL_I18N allow for validation of characters within a particular characterset

REM   Script: 18c character encoding validation 


REM   New routines in UTL_I18N allow for validation of characters within a particular characterset 


select *  from database_properties  
where property_name in ('NLS_NCHAR_CHARACTERSET','NLS_CHARACTERSET') ;

drop table charset_test;

create table charset_test(col1 varchar2(20), col2 nvarchar2(20)) ;

insert into charset_test   
values(  
  unistr('foo\D800bar'),  
  unistr('foo\D800bar')  
) ;

commit


select * from charset_test ;

select   
  utl_i18n.validate_character_encoding(col1) invalid_offset_column1,  
  utl_i18n.validate_character_encoding(col2) invalid_offset_column2  
from charset_test ;

