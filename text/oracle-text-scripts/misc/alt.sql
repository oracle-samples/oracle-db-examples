drop table my_custom_xml;

create table my_custom_xml(id number, col1 xmltype, col2 xmltype, col3 xmltype, dummycol xmltype);


insert into my_custom_xml(id, col1, col2) values (1,
'<?xml version="1.0"?>
<tag3 xmlns="http://www.abc.com">
<tag2>
<tag1>val1</tag1>
<pathtoObject>test data</pathtoObject>
</tag2>
</tag3>',
'<?xml version="1.0"?>
<tag4 xmlns="http://www.abc.com">
<tag5>
<tag6>3.0</tag6>
<pathtoObject>test data</pathtoObject>
</tag5>
</tag4>');

Insert into my_custom_xml(id, col1, col2) values (2,
'<?xml version="1.0"?>
<tag3 xmlns="http://www.abc.com">
<tag2>
<tag1>another val</tag1>
<pathtoObject>another test data</pathtoObject>
</tag2>
</tag3>',
'<?xml version="1.0"?>
<tag4 xmlns="http://www.abc.com">
<tag5>
<tag6>5.0</tag6>
<pathtoObject>another test data</pathtoObject>
</tag5>
</tag4>');


-- create multicolumn datastore
begin
 ctx_ddl.create_preference ('multi_ds_1', 'multi_column_datastore');
 ctx_ddl.set_attribute ('multi_ds_1', 'columns', 'xmlelement("ALL",col1,col2,col3).getclobval() xml_cols');
end;
/

exec ctx_ddl.drop_section_group('xmlpathsection_xml')

-- create path section group
begin
  ctx_ddl.create_section_group('xmlpathsection_xml', 'PATH_SECTION_GROUP');
end;
/

drop index multi_xml_payload;
create index multi_xml_payload on my_custom_xml(dummycol) indextype is ctxsys.context parameters
('datastore multi_ds_1 section group xmlpathsection_xml MEMORY 20m SYNC(ON COMMIT)');

-- now run the query

select extract(dummycol, '/pathtoObject/text()', 'xmlns="http://www.abc.com"') "Client Ref" from my_custom_xml where contains(dummycol, '(((val1 within tag1) within tag2) within tag3) within ALL') > 0;


-- Now instead of above query which is  i want to use xpath, so it should be transformed to . 
-- But looks like it's not supported if i go with above approach. Also for numbers i can't use sdata/field sections 
-- because they can't be used with PATH_SECTION_GROUP.Any suggestions from your side ?*
-- Also my xml payloads are not uniform, they will have different*   
-- structures most of the time, so adding the field in section group on the*  
-- fly wouldn't help a lot. Because then i have to keep on updating the*   
-- section group and indexes, which would be too much load for the system,*   
-- especially when xml's are really big (say of Mbs) and there are million of records. I was thinking if*   
-- there's anything which can be feed to the system during indexing the*   
-- payload(attribute in the xml) so that it can treat the value as number*   
-- rather than string or may be dyring query i specify something. Like in Elastic search/SOLR it takes care of*   
-- datatypes on the fly, i really don't have to tell the system.*

select extract(col1, 'tag3/tag2/pathtoObject/text()','xmlns="http://www.abc.com"') "Client Ref" from my_custom_xml where contains(dummycol, 'another val INPATH (//ALL/tag3/tag2/tag1)') > 0 ;

--        Result -->
--
--
--Client Ref
--
--another test data
--
--        execute query

select extract(col1, 'tag3/tag2/pathtoObject/text()','xmlns="http://www.abc.com"') "Client Ref" from my_custom_xml where contains(dummycol, 'another val INPATH (//ALL/tag3/tag2/tag1) and test data INPATH (//ALL/tag4/tag5/pathtoObject)') > 0;


--+Question : Now i want query something like :--> **where
--contains(dummycol, 'another val INPATH (//ALL/tag3/tag2/tag1)') > 0
--AND existsNode(dummycol, '//ALL/tag4/tag5tag6 > 3') = 1;(basically
--fetch records where tag6 value is greater than 1 or so;


select extract(col1, 'tag3/tag2/pathtoObject/text()','xmlns="http://www.abc.com"') "Client Ref" from my_custom_xml where contains(dummycol, 'another val INPATH (//ALL/tag3/tag2/tag1) and test data INPATH (//ALL/tag4/tag5/pathtoObject)') > 0 and extractValue('/
