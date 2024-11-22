-- does multi-column datastore work with '*' as the column list?
-- Yes.

connect sys/password as sysdba

drop user testuser cascade;

grant connect,resource,ctxapp,unlimited tablespace to testuser identified by testuser;

connect testuser/testuser

create table testtable (fitemguid varchar2(50), fitemname varchar2(50), fsomething varchar2(40));

insert into testtable values ('abcdefg', 'Baseballs.png', 'helloworld');

begin
  ctx_ddl.create_preference('"FT_CLOUDOTSCOLL2_DST"','MULTI_COLUMN_DATASTORE');
  ctx_ddl.set_attribute('"FT_CLOUDOTSCOLL2_DST"','COLUMNS','*');
end;
/


begin
  ctx_ddl.create_section_group('"FT_CLOUDOTSCOLL2_SGP"','BASIC_SECTION_GROUP');
  ctx_ddl.add_sdata_section('"FT_CLOUDOTSCOLL2_SGP"','SDFITEMNAME','SDFITEMNAME','VARCHAR2');
  ctx_ddl.add_sdata_section('"FT_CLOUDOTSCOLL2_SGP"','SDFOWNERFULLNAME','SDFOWNERFULLNAME','VARCHAR2');
  ctx_ddl.add_sdata_section('"FT_CLOUDOTSCOLL2_SGP"','SDFLASTMODIFIERFULLNAME','SDFLASTMODIFIERFULLNAME','VARCHAR2');
  ctx_ddl.add_sdata_section('"FT_CLOUDOTSCOLL2_SGP"','SDXCAASGUID','SDXCAASGUID','VARCHAR2');
  ctx_ddl.add_sdata_section('"FT_CLOUDOTSCOLL2_SGP"','SDXPUBLISHEDTARGETS','SDXPUBLISHEDTARGETS','VARCHAR2');
  ctx_ddl.add_sdata_section('"FT_CLOUDOTSCOLL2_SGP"','SDFITEMTYPE','SDFITEMTYPE','VARCHAR2');
  ctx_ddl.add_sdata_column('"FT_CLOUDOTSCOLL2_SGP"','FLASTMODIFIEDDATE','"FLASTMODIFIEDDATE"');
  ctx_ddl.add_sdata_section('"FT_CLOUDOTSCOLL2_SGP"','SDDDOCFORMATTYPE','SDDDOCFORMATTYPE','VARCHAR2');
  ctx_ddl.add_sdata_section('"FT_CLOUDOTSCOLL2_SGP"','SDXAPPROVALSTATE','SDXAPPROVALSTATE','VARCHAR2');
  ctx_ddl.add_sdata_column('"FT_CLOUDOTSCOLL2_SGP"','FCREATEDATE','"FCREATEDATE"');
  ctx_ddl.add_sdata_column('"FT_CLOUDOTSCOLL2_SGP"','XPUBLISHEDVERSION','"XPUBLISHEDVERSION"');
  ctx_ddl.add_sdata_section('"FT_CLOUDOTSCOLL2_SGP"','SDFITEMGUID','SDFITEMGUID','VARCHAR2');
  ctx_ddl.add_sdata_section('"FT_CLOUDOTSCOLL2_SGP"','SDFTARGETGUID','SDFTARGETGUID','VARCHAR2');
  ctx_ddl.add_sdata_column('"FT_CLOUDOTSCOLL2_SGP"','DFILESIZE','"DFILESIZE"');
  ctx_ddl.add_field_section('"FT_CLOUDOTSCOLL2_SGP"','XAPPROVALSTATE','XAPPROVALSTATE',FALSE);
  ctx_ddl.add_field_section('"FT_CLOUDOTSCOLL2_SGP"','FLASTMODIFIER','FLASTMODIFIER',FALSE);
  ctx_ddl.add_field_section('"FT_CLOUDOTSCOLL2_SGP"','DDOCFORMATTYPE','DDOCFORMATTYPE',FALSE);
  ctx_ddl.add_field_section('"FT_CLOUDOTSCOLL2_SGP"','FOWNER','FOWNER',FALSE);
  ctx_ddl.add_field_section('"FT_CLOUDOTSCOLL2_SGP"','XCAASGUID','XCAASGUID',FALSE);
  ctx_ddl.add_field_section('"FT_CLOUDOTSCOLL2_SGP"','COLLECTIONGUIDS','COLLECTIONGUIDS',FALSE);
  ctx_ddl.add_field_section('"FT_CLOUDOTSCOLL2_SGP"','FCREATOR','FCREATOR',FALSE);
  ctx_ddl.add_field_section('"FT_CLOUDOTSCOLL2_SGP"','FOWNERLOGINNAME','FOWNERLOGINNAME',FALSE);
  ctx_ddl.add_field_section('"FT_CLOUDOTSCOLL2_SGP"','FCREATORLOGINNAME','FCREATORLOGINNAME',FALSE);
  ctx_ddl.add_field_section('"FT_CLOUDOTSCOLL2_SGP"','FLASTMODIFIERLOGINNAME','FLASTMODIFIERLOGINNAME',FALSE);
  ctx_ddl.add_field_section('"FT_CLOUDOTSCOLL2_SGP"','OTSMETA','OTSMETA',FALSE);
  ctx_ddl.add_field_section('"FT_CLOUDOTSCOLL2_SGP"','DRENDITION1','DRENDITION1',FALSE);
  ctx_ddl.add_field_section('"FT_CLOUDOTSCOLL2_SGP"','FCREATORFULLNAME','FCREATORFULLNAME',FALSE);
  ctx_ddl.add_field_section('"FT_CLOUDOTSCOLL2_SGP"','DRENDITION2','DRENDITION2',FALSE);
  ctx_ddl.add_field_section('"FT_CLOUDOTSCOLL2_SGP"','FITEMTYPE','FITEMTYPE',FALSE);
  ctx_ddl.add_field_section('"FT_CLOUDOTSCOLL2_SGP"','FPARENTGUIDS','FPARENTGUIDS',FALSE);
  ctx_ddl.add_field_section('"FT_CLOUDOTSCOLL2_SGP"','FITEMGUID','FITEMGUID',FALSE);
  ctx_ddl.add_field_section('"FT_CLOUDOTSCOLL2_SGP"','FPARENTGUID','FPARENTGUID',FALSE);
  ctx_ddl.add_field_section('"FT_CLOUDOTSCOLL2_SGP"','DREVLABEL','DREVLABEL',FALSE);
  ctx_ddl.add_field_section('"FT_CLOUDOTSCOLL2_SGP"','XPUBLISHEDTARGETS','XPUBLISHEDTARGETS',FALSE);
  ctx_ddl.add_field_section('"FT_CLOUDOTSCOLL2_SGP"','FTARGETGUID','FTARGETGUID',FALSE);
  ctx_ddl.add_zone_section('"FT_CLOUDOTSCOLL2_SGP"','FITEMNAME','FITEMNAME');
  ctx_ddl.add_zone_section('"FT_CLOUDOTSCOLL2_SGP"','FFOLDERDESCRIPTION','FFOLDERDESCRIPTION');
  ctx_ddl.add_zone_section('"FT_CLOUDOTSCOLL2_SGP"','FOWNERFULLNAME','FOWNERFULLNAME');
  ctx_ddl.add_zone_section('"FT_CLOUDOTSCOLL2_SGP"','DCONTENTS','DCONTENTS');
  ctx_ddl.add_zone_section('"FT_CLOUDOTSCOLL2_SGP"','FLASTMODIFIERFULLNAME','FLASTMODIFIERFULLNAME');
  ctx_ddl.add_zone_section('"FT_CLOUDOTSCOLL2_SGP"','CUSTOMMETADATA','CUSTOMMETADATA');
  ctx_ddl.add_zone_section('"FT_CLOUDOTSCOLL2_SGP"','DEXTENSION','DEXTENSION');
  ctx_ddl.add_field_section('"FT_CLOUDOTSCOLL2_SGP"','XTAG','XTAG',FALSE);
  ctx_ddl.add_field_section('"FT_CLOUDOTSCOLL2_SGP"','XIDCTESTSEARCHDISABLEMETAFIELD','XIDCTESTSEARCHDISABLEMETAFIELD',FALSE);
  ctx_ddl.add_field_section('"FT_CLOUDOTSCOLL2_SGP"','XIDCTESTSEARCHDELETEMETAFIELD','XIDCTESTSEARCHDELETEMETAFIELD',FALSE);
  ctx_ddl.add_field_section('"FT_CLOUDOTSCOLL2_SGP"','XSEARCHUNASSIGNMETAFIELD','XSEARCHUNASSIGNMETAFIELD',FALSE);
  ctx_ddl.add_field_section('"FT_CLOUDOTSCOLL2_SGP"','XTAGS','XTAGS',FALSE);
  ctx_ddl.add_field_section('"FT_CLOUDOTSCOLL2_SGP"','XCATEGORIES','XCATEGORIES',FALSE);
end;
/


create index testindex
  on testtable
      ("FITEMGUID")
  indextype is ctxsys.context
  parameters('
    datastore       "FT_CLOUDOTSCOLL2_DST"
    sync (manual)
  ')
/

select token_text, token_type from dr$testindex$i;

select fitemname from testtable where contains (fitemguid, 'baseballs') > 0;

