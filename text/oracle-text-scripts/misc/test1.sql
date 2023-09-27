drop table textofallo;

CREATE TABLE TEXTOFALLO OF SYS.XMLTYPE XMLTYPE STORE AS CLOB ;

insert into textofallo values(xmltype('<fallo><guid>C8EA47D4-9274-11D6-8607-0050DABAA208</guid>
<texto-sentencia/>
</fallo>'))
/
create index idx_textofallo on textofallo x (value(x))
INDEXTYPE IS ctxsys.context parameters('FILTER ctxsys.null_filter SECTION GROUP ctxsys.path_section_group');

select * from textofallo;

select * from textofallo t
 where contains (value(t), 'C8EA47D4-9274-11D6-8607-0050DABAA208 INPATH (//GUID)')>0
/

select * from textofallo t
where contains (value(t), 'C8EA47D4-9274-11D6-8607-0050DABAA208 INPATH (//guid)')>0
/
