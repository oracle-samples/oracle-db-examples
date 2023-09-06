select extract(xmltype(replace(ctx_report.index_size('ti', null, 'XML'),chr(10),'')),
 '//SIZE_OBJECT[SIZE_OBJECT_NAME="ROGER.DR$TI$I"]')
from dual
/
