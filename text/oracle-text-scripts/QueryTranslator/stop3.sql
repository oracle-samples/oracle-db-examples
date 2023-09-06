select extract(xmltype(ctx_report.index_size('ti', null, 'XML')),
 '//SIZE_OBJECT/SIZE_OBJECT_NAME[normalize-space(.) = "ROGER.DR$TI$I"]')
from dual
/
