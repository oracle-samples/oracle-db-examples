drop table decisao_arquivo;

CREATE TABLE "DECISAO_ARQUIVO" 
   (	"SQ_DECISAO" NUMBER(15,0), 
	"BI_ARQUIVO_XML" CLOB,
	"TX_ARQUIVO_XML_PARTE_ADV" CLOB, 
	"TX_ARQUIVO_XML_INTEIRO_TEOR" CLOB 
   );

insert into DECISAO_ARQUIVO (bi_arquivo_xml) values (
'<DECISAO>
  <SELECIONADA>N</SELECIONADA>
  <DT_DECISAO>2006-10-10</DT_DECISAO>
  <TX_EMENTA>RECURSO ORDINÁRIO. INVESTIGAÇÃO JUDICIAL. ABUSO DE PODER. PRELIMINAR. JOAQUIM DOMINGOS RORIZ PREJUDICIALIDADE. JULGAMENTO RCED Nº 613 e RO Nº 738. SANÇÃO PREVISTA NO ART. 1º, I, d, da LC Nº 64/90. INOCUIDADE. PREJUDICIALIDADE QUANTO
AOS DEMAIS RECORRIDOS.
  1. Exclui-se do pólo passivo da demanda o recorrido Joaquim Domingos Roriz, por força da apreciação, em julgados anteriores, dos fatos articulados neste recurso (RCEd nº 613, Rel. Min. Carlos Velloso; RO nº 738, 
Rel. Min. Carlos Madeira).
  2. Tratando-se da conduta prevista no art. 1º, I, d, da LC nº 64/90, queda-se prejudicada a análise do recurso ordinário, uma vez que a sanção legalmente prevista, caso aplicada, mostrar-se-ia absolutamente inócua, ante o decurso de
tempo ocorrido desde as eleições de 2002.
  3. Inteligência do verbete nº 19 da Súmula do TSE: "O prazo de inelegibilidade de três anos, por abuso de poder econômico ou político, é contado a partir da data da eleição em que se verificou (art. 22, XIV, da LC 64, de 18/5/90)"
  4. Recurso ordinário prejudicado.
  </TX_EMENTA>
  <TX_EMENTAP>RECURSO ORDINÁRIO. INVESTIGAÇÃO JUDICIAL. ABUSO DE PODER. PRELIMINAR. JOAQUIM DOMINGOS RORIZ PREJUDICIALIDADE. JULGAMENTO RCED Nº 613 e RO Nº 738. SANÇÃO PREVISTA NO ART. 1º, I, d, da LC Nº 64/90. INOCUIDADE. PREJUDICIALIDADE QUANTO
AOS DEMAIS RECORRIDOS.
  </TX_EMENTAP>
  <TD_EMENTAP>
  1. Exclui-se do pólo passivo da demanda o recorrido Joaquim Domingos Roriz, por força da apreciação, em julgados anteriores, dos fatos articulados neste recurso (RCEd nº 613, Rel. Min. Carlos Velloso; RO nº 738, 
Rel. Min. Carlos Madeira).
  </TX_EMENTAP>
  <TD_EMENTAP>
  2. Tratando-se da conduta prevista no art. 1º, I, d, da LC nº 64/90, queda-se prejudicada a análise do recurso ordinário, uma vez que a sanção legalmente prevista, caso aplicada, mostrar-se-ia absolutamente inócua, ante o decurso de
tempo ocorrido desde as eleições de 2002.
  </TX_EMENTAP>
  <TD_EMENTAP>
  3. Inteligência do verbete nº 19 da Súmula do TSE: "O prazo de inelegibilidade de três anos, por abuso de poder econômico ou político, é contado a partir da data da eleição em que se verificou (art. 22, XIV, da LC 64, de 18/5/90)"
  </TX_EMENTAP>
  <TD_EMENTAP>
  4. Recurso ordinário prejudicado.
  </TX_EMENTAP>
  <TX_DECISAO>O Tribunal, por unanimidade, julgou prejudicado o Recurso, na forma do voto do Relator. </TX_DECISAO>
  <AA_ELEICAO></AA_ELEICAO>
  <NR_UNICO></NR_UNICO>
<SG_CLASSE>RO</SG_CLASSE>
<DS_CLASSE>Recurso Ordinário</DS_CLASSE>
<NR_PROCESSO>697</NR_PROCESSO>
<NUDC></NUDC>
<TIPO_PROCESSO>439,RO,RECURSO ORDINÁRIO,</TIPO_PROCESSO>
<UF>DF</UF>
<MUNICIPIO>BRASÍLIA</MUNICIPIO>
<PROTOCOLOS>          214005,0,0</PROTOCOLOS>
<MINISTRO_RELATOR>JOSÉ AUGUSTO DELGADO</MINISTRO_RELATOR>
<PUBLICACOES>          156494,2,DJ - Diário de justiça, 1,,10/11/2006</PUBLICACOES>
<INDEXACAO>Exclusão, parte processual, lide, prejudicialidade, recurso, apreciação, matéria, anterioridade, recurso de diplomação, recurso ordinário, inexistência, comprovação, abuso do poder econômico, perda do objeto.
Prejudicialidade, recurso ordinário, investigação judicial, termo inicial, aplicação, inelegibilidade, decurso de prazo, sanção, contagem, triênio, posterioridade, data, eleições, (2002), perda do objeto. (CLE) ###  ### 
</INDEXACAO><CATALOGOS>##El0344 - MATÉRIA PROCESSUAL - PREJUDICIALIDADE - RECURSO      </CATALOGOS>
<REFERENCIA> #### LEG.: Federal LEI COMPLEMENTAR Nº.: 64 Ano: 1990( LC - LEI DE INELEGIBILIDADES ) ###  ## Art.: 22 - Inc.: 14 ## Art.: 1 - Inc.: 1 - Let: D ### 
</REFERENCIA>
<DOUTRINA></DOUTRINA>
<OBSERVACAO>(10 fls.)  ####      ####    </OBSERVACAO>
<VIDES></VIDES>
<PRECEDENTES></PRECEDENTES>
</DECISAO>'
);


SET DEFINE OFF

exec ctx_ddl.drop_stoplist('sem_stopwords')

begin
ctx_ddl.create_stoplist('sem_stopwords', 'BASIC_STOPLIST');
end;
/

exec ctx_ddl.drop_section_group('xmlsjurgroup')

begin
  ctx_ddl.drop_section_group('xmlsjurgroup'); 
end;
/

begin
  ctx_ddl.create_section_group('xmlsjurgroup', 'BASIC_SECTION_GROUP');
  ctx_ddl.add_field_section('xmlsjurgroup', 'muni', 'municipio', TRUE);
  ctx_ddl.add_field_section('xmlsjurgroup', 'clas', 'sg_classe', TRUE);
  ctx_ddl.add_field_section('xmlsjurgroup', 'dcla', 'ds_classe', TRUE);
  ctx_ddl.add_field_section('xmlsjurgroup', 'tipd', 'tipo_processo', TRUE);
  ctx_ddl.add_field_section('xmlsjurgroup', 'nupr', 'nr_processo', TRUE);
  ctx_ddl.add_field_section('xmlsjurgroup', 'nudc', 'nudc', TRUE);
  ctx_ddl.add_field_section('xmlsjurgroup', 'ufor', 'uf', TRUE);
  ctx_ddl.add_field_section('xmlsjurgroup', 'reld', 'ministro_designado', TRUE);
  ctx_ddl.add_field_section('xmlsjurgroup', 'relt', 'ministro_relator', TRUE);
  ctx_ddl.add_field_section('xmlsjurgroup', 'revd', 'ministro_revisor', TRUE);
  ctx_ddl.add_field_section('xmlsjurgroup', 'cata', 'catalogos', TRUE);
  ctx_ddl.add_field_section('xmlsjurgroup', 'inde', 'indexacao', TRUE);
--  ctx_ddl.add_field_section('xmlsjurgroup', 'emen', 'tx_ementa', TRUE);
  ctx_ddl.add_zone_section ('xmlsjurgroup', 'emen', 'tx_ementa');
  ctx_ddl.add_field_section('xmlsjurgroup', 'publ', 'publicacoes', TRUE);
  ctx_ddl.add_field_section('xmlsjurgroup', 'refl', 'referencia', TRUE);
  ctx_ddl.add_field_section('xmlsjurgroup', 'prec', 'precedentes', TRUE);
  ctx_ddl.add_field_section('xmlsjurgroup', 'obse', 'observacao', TRUE);
  ctx_ddl.add_field_section('xmlsjurgroup', 'deci', 'tx_decisao', TRUE);
  ctx_ddl.add_field_section('xmlsjurgroup', 'dout', 'doutrina', TRUE);
  ctx_ddl.add_field_section('xmlsjurgroup', 'vide', 'vides', TRUE);
  ctx_ddl.add_field_section('xmlsjurgroup', 'nuni', 'nr_unico', TRUE);
  ctx_ddl.add_field_section('xmlsjurgroup', 'dest', 'decisao_destaque', TRUE);
  ctx_ddl.add_special_section('xmlsjurgroup', 'PARAGRAPH'); 
  ctx_ddl.add_sdata_section('xmlsjurgroup','datd','dt_decisao','DATE');
  ctx_ddl.add_sdata_section('xmlsjurgroup','sele','selecionada','VARCHAR2');
end; 
/

CREATE INDEX IX_DECISAO_ARQUIVO_01 ON DECISAO_ARQUIVO
(BI_ARQUIVO_XML)
INDEXTYPE IS CTXSYS.CONTEXT
PARAMETERS('stoplist sem_stopwords datastore ctxsys.default_datastore lexer smjlex filter ctxsys.null_filter section group xmlsjurgroup SYNC (ON COMMIT)')
/

-- this should work
select count(*) from decisao_arquivo where contains ( bi_arquivo_xml, '((joaquim and roriz) within paragraph) within emen'	) > 0;

-- this should return 0
select count(*) from decisao_arquivo where contains ( bi_arquivo_xml, '((joaquim and anos) within paragraph) within emen'  ) > 0;
