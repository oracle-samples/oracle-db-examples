select replace(extractValue(value(e), ('//INDEX_STOP')), chr(10), '')
from table(xmlsequence(
   extract(xmltype(
     ctx_report.describe_index('ti','XML')
   ), '//INDEX_STOP[@STOP_TYPE="STOP_WORD"]'))) e
/

select ixv_value from ctx_user_index_values
  where ixv_index_name = 'TI'
  and ixv_class = 'STOPLIST'
  and ixv_attribute = 'STOP_WORD'
/

select extractValue(value(e), ('//INDEX_STOP'))
from table(xmlsequence(
   extract(xmltype(
     ctx_report.describe_index('ti','XML')
   ), '//INDEX_STOP[@STOP_TYPE="STOP_WORD"]'))) e
/

