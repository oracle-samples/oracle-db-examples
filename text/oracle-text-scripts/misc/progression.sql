drop table c
/
create table c(id varchar2(255), c_type_id number(4), data clob)
/ 
alter table c add constraint c_PK primary key (id, c_type_id)
/ 
insert all
 into c (id, c_Type_id, data) values
 ('POI_DE3_TAX_19701106_0001', 1701, '<n-docbody>
 			<poi class="id">POI_DE3_TAX_19701106_0001 DE3_TAX_19701106_0001</poi>
 			<poi class="pk">���a45�N11�� 6��</poi>
 			<poi class="fk">���a45�N 9��30��</poi>
			<poi class="abstract">���������l</poi>
		</n-docbody>')
into c (id, c_type_id, data) values
('POI_DE3_TAX_19700930_0002', 1701, '<n-docbody>
		        <poi class="id">POI_DE3_TAX_19700930_0002 DE3_TAX_19700930_0002</poi>
			<poi class="pk">DE3 ���a45�N 9��30��</poi>
			<poi class="fk">���a45�N11�� 6��</poi>
			<poi class="abstract">�L���،��̔�����</poi>
                        </n-docbody>')
into c (id, c_type_id, data) values
('POI_DE3_TAX_19701029_0003', 1701, '<n-docbody>
			<poi class="id">POI_DE3_TAX_19701029_0003 DE3_TAX_19701029_0003</poi>
			<poi class="pk">���a45�N10��29��</poi>
			<poi class="abstract">���a45�N11��6�� 0001�A�@���a45�N9��30�� </poi>
		</n-docbody>')
select * from dual
/ 

begin
	Ctx_Ddl.Drop_Preference('my_jp_lexer');
end;
/ 

begin
	Ctx_Ddl.Create_Preference('my_jp_lexer','JAPANESE_VGRAM_LEXER');
end;
/ 
begin
	ctx_ddl.drop_section_group('poigroup');
end;
/ 

begin
        ctx_ddl.create_section_group('poigroup', 'XML_SECTION_GROUP');
	ctx_ddl.add_zone_section('poigroup', 'poi', 'poi');
	ctx_ddl.add_attr_section('poigroup', 'poiclass', 'poi@class');
end;
/ 

CREATE INDEX
	c_txt_index ON c(DATA)
INDEXTYPE
	IS CTXSYS.CONTEXT
PARAMETERS(
		'transactional
		LEXER my_jp_lexer
		STOPLIST ctxsys.default_stoplist
		filter ctxsys.null_filter
		section group poigroup
		'
	  )
/ 

column id format a20

select
	id, score(1)
from c
where
	contains (data, '<query>
  				<textquery>
    					<progression>
      						<seq>(���a45�N11�� 6�� AND (id WITHIN poiclass)*10*10) WITHIN poi</seq>
      						<seq>(���a45�N11�� 6�� AND (pk WITHIN poiclass)*10*10) WITHIN poi</seq>
      						<seq>(���a45�N11�� 6�� AND (fk WITHIN poiclass)*10*10) WITHIN poi</seq>
      						<seq>(���a45�N11�� 6��) WITHIN poi</seq>
   					</progression>
  				</textquery>
			</query>', 1) > 0
order by
	score(1) desc
/ 
