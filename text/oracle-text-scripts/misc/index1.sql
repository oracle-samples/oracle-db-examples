exec ctx_ddl.drop_preference('contact_index_dst')

begin
  ctx_ddl.create_preference('"CONTACT_INDEX_DST"','MULTI_COLUMN_DATASTORE');
  ctx_ddl.set_attribute('"CONTACT_INDEX_DST"','COLUMNS','cont_fname, cont_lname,
 cont_jobtitle, last_upd');
end;
/

exec ctx_ddl.drop_section_group('contact_index_sgp')

begin
  ctx_ddl.create_section_group('"CONTACT_INDEX_SGP"','AUTO_SECTION_GROUP');
end;
/

exec ctx_ddl.drop_preference('contact_index_wdl')

begin
  ctx_ddl.create_preference('"CONTACT_INDEX_WDL"','BASIC_WORDLIST');
  ctx_ddl.set_attribute('"CONTACT_INDEX_WDL"','SUBSTRING_INDEX','YES');
  ctx_ddl.set_attribute('"CONTACT_INDEX_WDL"','PREFIX_INDEX','YES');
end;
/

drop index contact_index;

create index "TESTUSER"."CONTACT_INDEX"
  on "TESTUSER"."EXT_CONTACTS"
      ("CONT_FNAME")
  indextype is ctxsys.context
  filter by
    "APPLICATION_CODE",
    "CONT_ACTIVE_FLG"
  parameters('
    datastore	    "CONTACT_INDEX_DST"
    section group   "CONTACT_INDEX_SGP"
    wordlist	    "CONTACT_INDEX_WDL"
    sync (on commit)
  ')
/
