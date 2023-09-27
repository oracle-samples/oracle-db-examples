/* 

I finally got INDEX_SIZE done.  I find myself only having a few
hours here and there to work on this, with the endless meetings
and other responsibilities.  So here I am burning the midnight
oil, which is the only time I can get peace and quiet!

Also, the initial implementation of INDEX_SIZE was very slow.
11 sec for a simple index.  sql trace pointed to dba_segments
as the problem -- the view is too complex to use efficiently for
our purposes.  So I re-wrote it using the fixed views and 
multiple loops instead of one sql and now it performs adequately.
I took the opportunity to hand-tune the other SQL statements
in the package, as well.

I've incorporated some of Radomir's feedback as follows:

* I think prettying up ctx_ddl.set_attribute for storage options 
is a bit too hard for the payoff.

* prefname_prefix parameter added to create_index_script.
it defaults to NULL which will be interpreted as index_name.
defaulting to index_name directly is not correct as index_name
can contain owner name.  note length limit follows same rules
as index name (first error messages added to this package!)

* drop option to create_index_script - still considering

* replace option to create_preference - outside scope of this
project

* function API: added

I have found a problem with indexes on XMLType as it is a function-
based index under the covers, so the generated sql for create index
does not work.  I plan to follow up with XDB development (MK) to
see if the original column name can be recovered somehow.

updated ctestx is included in this drop.  Added dtest4, which
has partitioned $I table with local $X index, and dtest5, an
index on sys.xmltype.

also a slightly modified driutl.pkb -- I tuned one sql.

*/


create or replace package ctx_report as

/*--------------------------- describe_index --------------------------------*/
/*
  NAME
    describe_index

  DESCRIPTION
    create a report describing the index.  This includes the settings of
    the index meta-data, the indexing objects used, the settings of the
    attributes of the objects, and index partition descriptions, if any

  ARGUMENTS
    index_name (IN)     the name of the index to describe
    report     (IN OUT) CLOB locator to which to write the report

  NOTES
    if report is NULL, a session-duration temporary CLOB will be created
    and returned.  It is the caller's responsibility to free this temporary
    CLOB as needed.
 
    report clob will be truncated before report is generated, so any
    existing contents will be overwritten by this call
*/
procedure describe_index(
  index_name in varchar2,
  report     in out nocopy clob
);

function describe_index(
  index_name in varchar2
) return clob;

/*-------------------------- create_index_script ----------------------------*/
/*
  NAME
    create_index_script

  DESCRIPTION
    create a SQL*Plus script which will create a text index that duplicates 
    the named text index.  

  ARGUMENTS
    index_name      (IN)     the name of the index
    report          (IN OUT) CLOB locator to which to write the script
    prefname_prefix (IN)     optional prefix to use for preference names

  NOTES
    the created script will include creation of preferences identical to
    those used in the named text index

    if report is NULL, a session-duration temporary CLOB will be created
    and returned.  It is the caller's responsibility to free this temporary
    CLOB as needed.
 
    report clob will be truncated before report is generated, so any
    existing contents will be overwritten by this call

    if prefname_prefix is omitted or NULL, index name will be used
    prefname_prefix follows index length restrictions
*/
procedure create_index_script(
  index_name      in varchar2,
  report          in out nocopy clob,
  prefname_prefix in varchar2 default null
);

function create_index_script(
  index_name      in varchar2,
  prefname_prefix in varchar2 default null
) return clob;
  

/*--------------------------- index_size --------------------------------*/
/*
  NAME
    index_size

  DESCRIPTION
    create a report showing the internal objects of the text index or 
    text index partition, and their tablespaces, allocated, and used sizes

  ARGUMENTS
    index_name (IN)     the name of the index to describe
    report     (IN OUT) CLOB locator to which to write the report
    part_name  (IN)     the name of the index partition (optional)

  NOTES
    if part_name is NULL, and the index is a local partitioned text index,
    then all objects of all partitions will be displayed.  If part_name is
    provided, then only the objects of a particular partition will be
    displayed.

    if report is NULL, a session-duration temporary CLOB will be created
    and returned.  It is the caller's responsibility to free this temporary
    CLOB as needed.
 
    report clob will be truncated before report is generated, so any
    existing contents will be overwritten by this call
*/
procedure index_size(
  index_name in varchar2,
  report     in out nocopy clob,
  part_name  in varchar2 default null
);

function index_size(
  index_name  in varchar2,
  part_name   in varchar2 default null
) return clob;

end ctx_report;
/
show errors

create or replace package body ctx_report as

  type linetab is table of varchar2(600) index by binary_integer;
  pv_ltab linetab;
  pv_idx  number;

  type subxrec is record (
    collist varchar2(500),
    storage varchar2(500)
  );
  type subxtab is table of subxrec index by binary_integer;

  s60  varchar2(60) := 
   '                                                            ';
  e60  varchar2(60) := 
   '============================================================';
  h60  varchar2(60) := 
   '------------------------------------------------------------';

  pv_afterend varchar2(200);
  pv_pnpfx    varchar2(30);

/*==========================================================================*/
/*==========================================================================*/
/*                     PRIVATE PROCEDURES : OUTPUT HELPERS                  */
/*==========================================================================*/
/*==========================================================================*/

/*---------------------------- blankln -------------------------------*/

procedure blankln is
begin
  pv_ltab(pv_idx) := '';
  pv_idx := pv_idx + 1;
end blankln;


/*---------------------------- writeln -------------------------------*/

procedure writeln(lline in varchar2) is
begin
  pv_ltab(pv_idx) := lline;
  pv_idx := pv_idx + 1;
end writeln;


/*---------------------------- desctitle -------------------------------*/

procedure desctitle(
  title  in varchar2 default null,
  title2 in varchar2 default null,
  sep    in varchar2 default e60
)is
begin
  pv_ltab(pv_idx)   := sep;
  pv_ltab(pv_idx+1) := substr(s60,1,trunc((60-length(title))/2))||title;
  if (title2 is not null) then
    pv_ltab(pv_idx+2) := substr(s60,1,trunc((60-length(title2))/2))||title2;
    pv_ltab(pv_idx+3) := sep;
    pv_idx := pv_idx + 4;
  else
    pv_ltab(pv_idx+2) := sep;
    pv_idx := pv_idx + 3;
  end if;
exception
  when others then
    drue.text_on_stack(sqlerrm,'ctx_report.desctitle');
    raise dr_def.textile_error;
end desctitle;

/*---------------------------- descln -------------------------------*/

procedure descln(
  indent in number,
  label  in varchar2 default null,
  value  in varchar2 default null
)is
begin
  pv_ltab(pv_idx)   := substr(s60, 1, indent * 3)||
                       label||':'||
                       substr(s60, 1, abs(32 - length(label)))||
                       value;
  pv_idx := pv_idx + 1;
exception
  when others then
    drue.text_on_stack(sqlerrm,'ctx_report.descln');
    raise dr_def.textile_error;
end descln;

/*---------------------------- scriptcp -------------------------------*/

procedure scriptcp(
  idx      in     driutl.index_rec,
  l_cla_id in     number,
  l_obj    in     varchar2,
  pname    in out varchar2,
  affx     in     varchar2 default null
)is
  tla  varchar2(5);
  nme  varchar2(30) := 'preference';
  ion  boolean := TRUE;
  ismd boolean := FALSE;
begin
  if (l_cla_id = DRIOBJ.CLASS_DATASTORE) then
    tla := 'DST';
    if (l_obj = 'MULTI_COLUMN_DATASTORE') then
      ismd := TRUE;
    end if;
  elsif (l_cla_id = DRIOBJ.CLASS_DATATYPE) then
    tla := 'DSY';
  elsif (l_cla_id = DRIOBJ.CLASS_DATAX) then
    tla := 'DSX';
  elsif (l_cla_id = DRIOBJ.CLASS_FILTER) then
    tla := 'FIL';
  elsif (l_cla_id = DRIOBJ.CLASS_SECTION_GROUP) then
    tla := 'SGP';
    nme := 'section_group';
  elsif (l_cla_id = DRIOBJ.CLASS_LEXER) then
    tla := 'LEX';
  elsif (l_cla_id = DRIOBJ.CLASS_WORDLIST) then
    tla := 'WDL';
  elsif (l_cla_id = DRIOBJ.CLASS_STOPLIST) then
    tla := 'SPL';
    nme := 'stoplist';
  elsif (l_cla_id = DRIOBJ.CLASS_STORAGE) then
    tla := 'STO';
  elsif (l_cla_id = DRIOBJ.CLASS_INDEX_SET) then
    tla := 'IXS';
    nme := 'index_set';
    ion := FALSE;
  end if;

  if (affx is null) then
    pname := '"'||pv_pnpfx||'_'||tla||'"';
  else
    pname := '"'||pv_pnpfx||'_'||substr(tla,1,1)||affx||'"';
  end if;

  -- special case: only CTXSYS can create multi-datastore preference
  if (ismd) then
    writeln('connect CTXSYS/CTXSYS');
    blankln;
    pv_afterend := 'connect '||idx.idx_owner||'/'||idx.idx_owner;
  end if;

  pv_ltab(pv_idx  ) := 'begin';
  if (ion) then
    pv_ltab(pv_idx+1) := '  ctx_ddl.create_'||nme||'('''||pname||''','''||
                         l_obj||''');';
  else
    pv_ltab(pv_idx+1) := '  ctx_ddl.create_'||nme||'('''||pname||''');';
  end if;

  pv_idx := pv_idx + 2;

exception
  when others then
    drue.text_on_stack(sqlerrm,'ctx_report.scriptcp');
    raise dr_def.textile_error;
end scriptcp;

/*---------------------------- scriptsa -------------------------------*/

procedure scriptsa(
  pname    in varchar2,
  l_cla_id in number,
  attr     in varchar2,
  value    in varchar2,
  val2     in varchar2 default null,
  val3     in varchar2 default null
)is
  calln  varchar2(30) := null;
  ival3   varchar2(30) := null;
begin
  if (l_cla_id = DRIOBJ.CLASS_STOPLIST) then
    if (attr = 'STOP_WORD') then
      calln := 'add_stopword';
    elsif (attr = 'STOP_THEME') then
      calln := 'add_stoptheme';
    elsif (attr = 'STOP_CLASS') then
      calln := 'add_stopclass';
    end if;
  elsif (l_cla_id = DRIOBJ.CLASS_SECTION_GROUP) then
    if (attr = 'ZONE') then
      calln := 'add_zone_section';
    elsif (attr = 'FIELD') then
      calln := 'add_field_section';
      if (val3 = 'Y') then ival3 := 'TRUE'; else ival3 := 'FALSE'; end if;
    elsif (attr = 'ATTR') then
      calln := 'add_attr_section';
    elsif (attr = 'SPECIAL') then
      calln := 'add_special_section';
    elsif (attr = 'STOP') then
      calln := 'add_stop_section';
    end if;
  elsif (l_cla_id = DRIOBJ.CLASS_INDEX_SET) then
    calln := 'add_index';
  end if;

  if (calln is null) then
    pv_ltab(pv_idx) := '  ctx_ddl.set_attribute('''||pname||''','''||
                       attr||''','''||value||'''';
  else
    pv_ltab(pv_idx) := '  ctx_ddl.'||calln||'('''||pname||''','''||
                       value||'''';
  end if;

  if (val2 is not null) then
    pv_ltab(pv_idx) := pv_ltab(pv_idx)||','''||val2||'''';
    if (val3 is not null) then
      pv_ltab(pv_idx) := pv_ltab(pv_idx)||','||ival3;
    end if;
  end if;

  pv_ltab(pv_idx) := pv_ltab(pv_idx)||');';
  pv_idx := pv_idx + 1;
  
exception
  when others then
    drue.text_on_stack(sqlerrm,'ctx_report.scriptsa');
    raise dr_def.textile_error;
end scriptsa;

/*---------------------------- scriptend -------------------------------*/

procedure scriptend is
begin
  pv_ltab(pv_idx  ) := 'end;';
  pv_ltab(pv_idx+1) := '/';
  pv_ltab(pv_idx+2) := '';
  pv_idx := pv_idx + 3;

  if (pv_afterend is not null) then
    blankln;
    writeln(pv_afterend);
    blankln;
    pv_afterend := null;
  end if;

exception
  when others then
    drue.text_on_stack(sqlerrm,'ctx_report.scriptend');
    raise dr_def.textile_error;
end scriptend;


/*---------------------------- sizeln -------------------------------*/

procedure sizeln(
  label  in varchar2 default null,
  value  in varchar2 default null,
  tk     in number   default null,
  uk     in number   default null,
  tb     in number   default null,
  ub     in number   default null
)is
  sstr varchar2(80);
begin
  if (label is not null) then
    pv_ltab(pv_idx)   := rpad(label||':',32)||value;
    pv_idx := pv_idx + 1;
  else
    pv_ltab(pv_idx)   := rpad(value||'BLOCKS ALLOCATED:',32)||lpad(tk, 30);
    pv_ltab(pv_idx+1) := rpad(value||'BLOCKS USED:',32)||lpad(tk-uk, 30);

    sstr := to_char(tb,'999,999,999,999')||' ('||
            ltrim(to_char(tb/1048576,'999,999,999,999'))||' MB)';
    pv_ltab(pv_idx+2) := rpad(value||'BYTES ALLOCATED:',32)||lpad(sstr,30);

    sstr := to_char(tb-ub,'999,999,999,999')||' ('||
            ltrim(to_char((tb-ub)/1048576,'999,999,999,999'))||' MB)';
    pv_ltab(pv_idx+3) := rpad(value||'BYTES USED:',32)||lpad(sstr, 30);
    pv_idx := pv_idx + 4;
  end if;
exception
  when others then
    drue.text_on_stack(sqlerrm,'ctx_report.sizeln');
    raise dr_def.textile_error;
end sizeln;

/*==========================================================================*/
/*==========================================================================*/
/*                     PRIVATE PROCEDURES : GENERIC                         */
/*==========================================================================*/
/*==========================================================================*/

/*---------------------------- initreport ---------------------------------*/

procedure initreport
is
begin
  pv_idx := 1;
  pv_ltab.delete;
exception
  when dr_def.textile_error then
    raise dr_def.textile_error;
  when others then
    drue.text_on_stack(sqlerrm, 'ctx_report.initreport');
    raise dr_def.textile_error;
end initreport;

/*---------------------------- endreport ---------------------------------*/

procedure endreport(report in out nocopy clob)
is
  nl varchar2(5) := '
';
   i number;
begin
  if (report is null) then
    dbms_lob.createtemporary(report, TRUE, dbms_lob.session);
  else
    dbms_lob.trim(report, 0);
  end if;

  for i in 1..pv_ltab.count loop
    if (pv_ltab(i) is null) then
      dbms_lob.writeappend(report, length(nl), nl);
    else
      dbms_lob.writeappend(report, length(pv_ltab(i))+length(nl),
                           pv_ltab(i)||nl);
    end if;
  end loop;
 
  pv_idx := 1;
  pv_ltab.delete;
exception
  when dr_def.textile_error then
    raise dr_def.textile_error;
  when others then
    drue.text_on_stack(sqlerrm, 'ctx_report.endreport');
    raise dr_def.textile_error;
end endreport;

/*---------------------- report_index_values -----------------------------*/

procedure report_index_values (
  idx      in driutl.index_rec,
  pname    in varchar2,
  l_cla_id in number,
  l_obj_id in number
) is
  colpos1 number;
  colpos2 number;
  colpos3 number;
  labbr   varchar2(4);
  labbr2  varchar2(4);
  lang    varchar2(30);
  secname varchar2(30);
  sectag  varchar2(30);
  fid     varchar2(10);
  visible varchar2(4);
  idxnum  number;
  isvals  subxtab;
  i       number;
begin
  for c1 in (select /*+ ORDERED USE_NL(oal) INDEX(oal) */
                    oat_name,
                    decode(oat_datatype,'B',decode(ixv_value, 1,'YES','NO'),
                           nvl(oal_label,ixv_value)) ixv_value
               from dr$index_value,
                    dr$object_attribute,
                    dr$object_attribute_lov oal
              where ixv_sub_group = 0
                and ixv_value = nvl(oal_value, ixv_value)
                and oat_id = oal_oat_id (+)
                and oat_system = 'N'
                and oat_cla_id = l_cla_id
                and oat_obj_id = l_obj_id
                and ixv_oat_id = oat_id
                and ixv_idx_id = idx.idx_id
              order by ixv_oat_id)
   loop
     -- special formatting cases:
     --   multi-language stopwords
     --   sections
     --   index set

     if (l_cla_id = DRIOBJ.CLASS_STOPLIST and
         l_obj_id = DRIOBJ.OBJ_MULTI_STOPLIST and
         c1.oat_name = 'STOP_WORD') 
     then
       colpos1 := instr(c1.ixv_value, ':');
       labbr := substr(c1.ixv_value, 1, colpos1 - 1);
       if (labbr = 'ALL') then
         lang := 'ALL';
       else
         if (not driutl.check_language(labbr, lang, labbr2, FALSE)) then
           lang := 'UNKNOWN LANGUAGE';
         end if;
       end if;
       if (pname is null) then
         descln(1, 'stop_word '||lower(lang), 
                substr(c1.ixv_value, colpos1 + 1));
       else
         scriptsa(pname, l_cla_id, c1.oat_name, 
                  substr(c1.ixv_value, colpos1 + 1), lang);
       end if;
     elsif (l_cla_id = DRIOBJ.CLASS_SECTION_GROUP) then
       colpos1 := instr(c1.ixv_value, ':');
       colpos2 := instr(c1.ixv_value, ':', -1, 2);
       colpos3 := instr(c1.ixv_value, ':', -1);
       secname := substr(c1.ixv_value, 1, colpos1 - 1);
       sectag  := substr(c1.ixv_value, colpos1 + 1, colpos2 - colpos1 - 1);
       fid     := substr(c1.ixv_value, colpos2 + 1, colpos3 - colpos2 - 1);
       visible := substr(c1.ixv_value, colpos3 + 1);
       if (pname is null) then
         descln(1, lower(c1.oat_name)||' section', secname);
         if (c1.oat_name = 'FIELD') then
           descln(2, 'section tag', sectag);
           descln(2, 'field id', fid);         
           if (visible = 'Y') then
             descln(2, 'visible', 'YES');
           else
             descln(2, 'visible', 'NO');
           end if;
         elsif (c1.oat_name != 'SPECIAL') then
           descln(2, 'section tag', sectag);
         end if;
       else
         scriptsa(pname, l_cla_id, c1.oat_name, secname, sectag, visible);
       end if;
     elsif (l_cla_id = DRIOBJ.CLASS_INDEX_SET) then
       colpos1 := instr(c1.ixv_value, ':');
       idxnum := substr(c1.ixv_value, 1, colpos1 - 1);
       if (c1.oat_name = 'COLUMN_LIST') then
         isvals(idxnum).collist := substr(c1.ixv_value, colpos1+1);
       else
         isvals(idxnum).storage := substr(c1.ixv_value, colpos1+1);
       end if;
     else
       if (pname is null) then
         descln(1, lower(c1.oat_name), c1.ixv_value);
       else
         scriptsa(pname, l_cla_id, c1.oat_name, c1.ixv_value);
       end if;
     end if;
   end loop;

   -- deferred output: index sets
   if (l_cla_id = DRIOBJ.CLASS_INDEX_SET) then
     for i in 1..isvals.count loop
       if (pname is null) then
         descln(1, 'index '||ltrim(to_char(i,'09')), isvals(i).collist);
         if (isvals(i).storage is not null) then
           descln(2, 'storage clause', isvals(i).storage);
         end if;
       else
         scriptsa(pname, l_cla_id, 'INDEX', 
                  isvals(i).collist, isvals(i).storage);
       end if;
     end loop;
   end if;

exception
  when dr_def.textile_error then
    drue.raise;
  when others then
    drue.text_on_stack(sqlerrm, 'ctx_report.report_index_values');
    drue.raise;
end report_index_values;

/*------------------- report_index_sub_values -----------------------------*/

procedure report_index_sub_values (
  idx         in driutl.index_rec,
  pname       in varchar2,
  l_cla_id    in number,
  l_oat_id    in number,
  l_sub_group in number,
  ind         in number
) is
begin
  for c1 in (select /*+ ORDERED USE_NL(oal) INDEX(oal) */
                    oat_name,
                    decode(oat_datatype,'B',decode(ixv_value, 1,'YES','NO'),
                           nvl(oal_label,ixv_value)) ixv_value
               from dr$index_value,
                    dr$object_attribute,
                    dr$object_attribute_lov oal
              where ixv_sub_group = l_sub_group
                and ixv_value = nvl(oal_value, ixv_value)
                and oat_id = oal_oat_id (+)
                and oat_system = 'N'
                and ixv_oat_id = l_oat_id
                and ixv_sub_oat_id = oat_id
                and ixv_idx_id = idx.idx_id
              order by ixv_sub_oat_id)
   loop
     if (pname is null) then
       descln(ind, lower(c1.oat_name), c1.ixv_value);
     else
       scriptsa(pname, l_cla_id, c1.oat_name, c1.ixv_value);
     end if;
   end loop;

exception
  when dr_def.textile_error then
    drue.raise;
  when others then
    drue.text_on_stack(sqlerrm, 'ctx_report.report_index_sub_values');
    drue.raise;
end report_index_sub_values;

/*---------------------- report_multi_lexer ------------------------------*/

procedure report_multi_lexer (
  idx      in driutl.index_rec,
  pname    in varchar2
) is
  l_oat_id_sl number;
  l_oat_id_sla number;
  colpos1 number;
  colpos2 number;
  labbr   varchar2(4);
  abb2    varchar2(4);
  lang    varchar2(30);
  slobj   varchar2(30);
  lalt    varchar2(30);
  splang  driutl.arr_table;
  spname  driutl.arr_table;
  spalt   driutl.arr_table;
  sidx    number := 1;
  i       number;
begin
  select oat_id into l_oat_id_sl 
    from dr$object_attribute
   where oat_cla_id = DRIOBJ.CLASS_LEXER 
     and oat_obj_id = DRIOBJ.OBJ_MULTI_LEXER
     and oat_name = 'SUB_LEXER';

  select oat_id into l_oat_id_sla
    from dr$object_attribute
   where oat_cla_id = DRIOBJ.CLASS_LEXER 
     and oat_obj_id = DRIOBJ.OBJ_MULTI_LEXER
     and oat_name = 'SUB_LEXER_ATTR';

  for c1 in (select ixv_value, ixv_sub_group
               from dr$index_value
              where ixv_oat_id = l_oat_id_sl
                and ixv_idx_id = idx.idx_id
              order by ixv_sub_group)
  loop
    colpos1 := instr(c1.ixv_value, ':');
    colpos2 := instr(c1.ixv_value, ':', colpos1 + 1);
    labbr   := substr(c1.ixv_value, 1, colpos1 - 1);
    slobj   := substr(c1.ixv_value, colpos1 + 1, colpos2 - colpos1 - 1);
    lalt    := substr(c1.ixv_value, colpos2 + 1);

    if (labbr = '00') then
      lang := 'DEFAULT';
    else
      if (not driutl.check_language(labbr, lang, abb2, TRUE)) then
        lang := 'UNKNOWN LANGUAGE';
      end if;
    end if;

    if (pname is null) then
      descln(1, 'sublexer '||lower(lang), slobj);
      if (lalt is not null) then
        descln(2, 'alternate language value', lalt);
      end if;
      report_index_sub_values(idx, null, DRIOBJ.CLASS_LEXER, 
                              l_oat_id_sla, c1.ixv_sub_group, 2);
    else
      splang(sidx) := lang;
      spname(sidx) := null;
      spalt(sidx)  := lalt;
      scriptcp(idx, DRIOBJ.CLASS_LEXER, slobj, spname(sidx), labbr);
      report_index_sub_values(idx, spname(sidx), DRIOBJ.CLASS_LEXER, 
                              l_oat_id_sla, c1.ixv_sub_group, 2);
      sidx := sidx + 1;
      scriptend;
    end if;

  end loop;

  -- deferred action: add_sub_lexer calls
  if (pname is not null) then
    writeln('begin');
    for i in 1..spname.count loop
      if (spalt(i) is null) then
        writeln('  ctx_ddl.add_sub_lexer('''||pname||''','''||splang(i)||
                ''','''||spname(i)||''');');
      else       
        writeln('  ctx_ddl.add_sub_lexer('''||pname||''','''||splang(i)||
                ''','''||spname(i)||''','''||spalt(i)||''');');      
      end if;
    end loop;
    scriptend;
  end if;

exception
  when dr_def.textile_error then
    drue.raise;
  when others then
    drue.text_on_stack(sqlerrm, 'ctx_report.report_multi_lexer');
    drue.raise;
end report_multi_lexer;

/*------------------------ size_index_object -------------------------------*/

procedure size_index_object (
  owner  in  varchar2,
  name   in  varchar2,
  otype  in  varchar2,
  tsname in  varchar2,
  pname  in  varchar2,
  tname  in  varchar2,
  itype  in  varchar2,
  tka   in out number,
  tku   in out number,
  tba   in out number,
  tbu   in out number
) is
  tk number;
  uk number;
  tb number;
  ub number;
  d1 number;
  d2 number;
  d3 number;
begin
  dbms_space.unused_space(owner, name, otype, 
                          tk, tb, uk, ub, d1, d2, d3, pname);
  if (otype like 'INDEX%') then
    sizeln('INDEX ('||itype||')', owner||'.'||name);
  else
    sizeln('TABLE', owner||'.'||name);
  end if;

  if (pname is not null) then
    sizeln(otype, pname);
  end if;

  if (otype like 'INDEX%') then
    sizeln('TABLE NAME',tname);
  end if;

  sizeln('TABLESPACE NAME', tsname);
  sizeln(null, null, tk, uk, tb, ub);
  blankln;
  tka := tka + tk; tku := tku + (tk - uk);
  tba := tba + tb; tbu := tbu + (tb - ub);
exception
  when dr_def.textile_error then
    drue.raise;
  when others then
    drue.text_on_stack(sqlerrm, 'ctx_report.size_index_object');
    drue.raise;
end size_index_object;

/*------------------------ size_index_part ---------------------------------*/

procedure size_index_part (
  idx   in  driutl.index_rec,
  ixp   in  driutl.ixp_rec,
  tka   in out number,
  tku   in out number,
  tba   in out number,
  tbu   in out number
) is
  ltka number := 0;
  ltku number := 0;
  ltba number := 0;
  ltbu number := 0;
  l_user# number;
  pfx  varchar2(30);
BEGIN

  -- generate table name pattern
  pfx := ltrim(driutl.make_pfx(null, idx.idx_name, '$', ixp.ixp_id) ,'"')||'_';

  -- get user#
  l_user# := driutl.get_user_id(idx.idx_owner);

  -- main select: select on tables 
  for c1 in (select /*+ORDERED*/ o.name tab, ts.name ts, o.obj#, t.dataobj#
               from sys.obj$ o, sys.tab$ t, sys.ts$ ts
              where ts.ts# = t.ts#
                and t.obj# = o.obj#
                and o.name like pfx
                and o.owner# = l_user#)
  loop
    -- if dataobj# is null then table is partitioned.  Otherwise, not.
    if (c1.dataobj# is not null) then
      size_index_object(idx.idx_owner, c1.tab, 'TABLE', c1.ts,
                        null, null, null, 
                        ltka, ltku, ltba, ltbu);
    else
      -- get table partitions
      for c2 in (select /*+ORDERED*/ o.subname part, ts.name ts, o.obj#
                   from sys.tabpart$ tp, sys.obj$ o, sys.ts$ ts
                  where ts.ts# = tp.ts#
                    and tp.obj# = o.obj#
                    and tp.bo# = c1.obj#)
      loop
        size_index_object(idx.idx_owner, c1.tab, 'TABLE PARTITION', c2.ts,
                          c2.part, null, null, 
                          ltka, ltku, ltba, ltbu);
      end loop;
    end if;

    -- now scan for indexes on this table
    for c3 in (select /*+ORDERED*/ 
                      u.name owner, o.name, 
                      decode(i.type#,1,'NORMAL',2,'BITMAP',3,'CLUSTER', 
                                     4,'IOT',5,'IOT',6,'SECONDARY',
                                     7,'ANSI',8,'LOB',9,'DOMAIN') itype,
                      o.obj#, o.dataobj#, ts.name ts
                 from sys.ind$ i, sys.obj$ o, sys.user$ u, sys.ts$ ts
                where ts.ts# = i.ts#
                  and u.user# = o.owner#
                  and i.obj# = o.obj#
                  and i.bo# = c1.obj#)
    loop
      if (c3.dataobj# is not null) then
        size_index_object(c3.owner, c3.name, 'INDEX', c3.ts,
                          null, idx.idx_owner||'.'||c1.tab, c3.itype, 
                          ltka, ltku, ltba, ltbu);
      else
        -- get index partitions
        for c4 in (select /*+ORDERED*/ o.subname part, ts.name ts, o.obj#
                     from sys.indpart$ ip, sys.obj$ o, sys.ts$ ts
                    where ts.ts# = ip.ts#
                      and ip.obj# = o.obj#
                      and ip.bo# = c3.obj#)
        loop
          size_index_object(c3.owner, c3.name, 'INDEX PARTITION', c4.ts,
                            c4.part, idx.idx_owner||'.'||c1.tab, c3.itype,
                            ltka, ltku, ltba, ltbu);
        end loop;
      end if;
    end loop;
  end loop;

  if (ixp.ixp_id is not null) then
    writeln('TOTALS FOR INDEX PARTITION '||ixp.ixp_name);
    writeln(h60);
    sizeln(null, 'TOTAL ', ltka, ltku, ltba, ltbu);    
    blankln;
  end if;

  tka := tka + ltka; tku := tku + ltku; tba := tba + ltba; tbu := tbu + ltbu;

exception
  when dr_def.textile_error then
    drue.raise;
  when others then
    drue.text_on_stack(sqlerrm, 'ctx_report.size_index_part');
    drue.raise;
end size_index_part;


/*==========================================================================*/
/*==========================================================================*/
/*                          PUBLIC PROCEDURES                               */
/*==========================================================================*/
/*==========================================================================*/

/*------------------------- describe_index ---------------------------------*/

procedure describe_index(
  index_name in varchar2,
  report     in out nocopy clob
)
is
  idx    driutl.index_rec;
  ixp    driutl.ixp_rec;
  l_oat_id number;
begin
  initreport;
   
  -- dump index meta-data
  idx := driutl.get_index(index_name);
  desctitle('INDEX DESCRIPTION');

  descln(0, 'index name', '"'||idx.idx_owner||'"."'||idx.idx_name||'"');
  descln(0, 'index id', idx.idx_id);
  if (idx.idx_type = driddl.idx_type_context) then
    descln(0, 'index type','context');
  elsif (idx.idx_type = driddl.idx_type_ctxcat) then
    descln(0, 'index type','ctxcat');
  elsif (idx.idx_type = driddl.idx_type_ctxrule) then
    descln(0, 'index type','ctxrule');
  end if;

  blankln;

  descln(0,'base table','"'||idx.idx_table_owner||'"."'||idx.idx_table||'"');
  descln(0,'primary key column', idx.idx_key_name);
  descln(0,'text column', idx.idx_text_name);
  if (idx.idx_text_type = 1) then
    descln(0,'text column', 'VARCHAR2('||idx.idx_text_length||')');
  elsif (idx.idx_text_type = 8) then
    descln(0,'text column', 'LONG');
  elsif (idx.idx_text_type = 9) then
    descln(0,'text column', 'VARCHAR('||idx.idx_text_length||')');
  elsif (idx.idx_text_type = 23) then
    descln(0,'text column', 'RAW('||idx.idx_text_length||')');
  elsif (idx.idx_text_type = 24) then
    descln(0,'text column', 'LONG RAW');
  elsif (idx.idx_text_type = 96) then
    descln(0,'text column', 'CHAR('||idx.idx_text_length||')');
  elsif (idx.idx_text_type = 112) then
    descln(0,'text column', 'CLOB');
  elsif (idx.idx_text_type = 113) then
    descln(0,'text column', 'BLOB');
  elsif (idx.idx_text_type = 114) then
    descln(0,'text column', 'BFILE');
  elsif (idx.idx_text_type = 10000) then
    descln(0,'text column', 'SYS.XMLTYPE');
  else
    descln(0,'text column', idx.idx_text_type);
  end if;
  descln(0,'language column', idx.idx_language_column);
  descln(0,'format column', idx.idx_format_column);
  descln(0,'charset column', idx.idx_charset_column);

  blankln;

  if (idx.idx_option like '%P%') then
    descln(0,'index option', 'local partitioned');
  end if;
  if (idx.idx_option like '%F%') then
    descln(0,'index option', 'function-based');
  end if;

  if (idx.idx_option not like '%P%') then
    blankln;

    descln(0,'status', idx.idx_status);
    if (idx.idx_opt_token is not null) then
      descln(0,'full optimize token', 
              idx.idx_opt_token||','||idx.idx_opt_type);
    else
      descln(0,'full optimize token', '');
    end if;
    descln(0,'full optimize count', idx.idx_opt_count);
    descln(0,'docid count', idx.idx_docid_count);
    descln(0,'nextid', idx.idx_nextid);
  end if;

  -- now indexing objects
  blankln;
  desctitle('INDEX OBJECTS');
 
  for c1 in (select /*+ORDERED*/ cla_id, cla_name, obj_id, obj_name
               from dr$index_object, dr$class, dr$object
              where cla_system = 'N'
                and ixo_cla_id = cla_id
                and ixo_cla_id = obj_cla_id
                and ixo_obj_id = obj_id
                and ixo_idx_id = idx.idx_id
              order by cla_id)
  loop
    -- skip certain classes for certain index types
    if (idx.idx_type = driddl.idx_type_context or
        idx.idx_type = driddl.idx_type_ctxrule or
        (idx.idx_type = driddl.idx_type_ctxcat and 
         c1.cla_id >= DRIOBJ.CLASS_LEXER))
    then
      descln(0,translate(lower(c1.cla_name),'_',' '), c1.obj_name);
      if (c1.cla_id = DRIOBJ.CLASS_LEXER and
          c1.obj_id = DRIOBJ.OBJ_MULTI_LEXER) then
        report_multi_lexer(idx, null);
      else
        report_index_values(idx, null, c1.cla_id, c1.obj_id);
      end if;
      blankln;
    end if;
  end loop;

  -- now index partition
  if (idx.idx_option like '%P%') then
    blankln;
    desctitle('INDEX PARTITIONS');

    -- look up oat_id for PART_SUB_STORAGE_ATTR
    select oat_id into l_oat_id from dr$object_attribute
     where oat_cla_id = DRIOBJ.CLASS_STORAGE
       and oat_obj_id = DRIOBJ.OBJ_BASIC_STORAGE
       and oat_name = 'PART_SUB_STORAGE_ATTR';

    for c1 in (select /*+INDEX(ip drc$ixp_key)*/ ixp_id 
                 from dr$index_partition ip
                where ixp_idx_id = idx.idx_id
                order by ixp_idx_id, ixp_id)
    loop
      ixp := driutl.get_ipartition_by_id(c1.ixp_id, idx.idx_id);

      descln(1, 'index partition', ixp.ixp_name);
      descln(2, 'table partition', ixp.ixp_table_partition);
      descln(2, 'index partition id', ixp.ixp_id);
      descln(2,'status', ixp.ixp_status);
      if (ixp.ixp_opt_token is not null) then
        descln(2,'full optimize token', 
                idx.idx_opt_token||','||ixp.ixp_opt_type);
      else
        descln(2,'full optimize token', '');
      end if;
      descln(2,'full optimize count', ixp.ixp_opt_count);
      descln(2,'docid count', ixp.ixp_docid_count);
      descln(2,'nextid', ixp.ixp_nextid);

      report_index_sub_values(idx, null, DRIOBJ.CLASS_STORAGE, 
                              l_oat_id, ixp.ixp_id, 2);
      blankln;
    end loop;
  end if;

  endreport(report);

exception
  when dr_def.textile_error then
    drue.raise;
  when others then
    drue.text_on_stack(sqlerrm, 'ctx_report.describe_index');
    drue.raise;
end describe_index;

/*------------------------- describe_index (fn) ---------------------------*/

function describe_index(
  index_name  in varchar2
) return clob
is
  x clob;
begin
  dbms_lob.createtemporary(x, TRUE, DBMS_LOB.CALL);
  describe_index(index_name, x);
  return x;  
end describe_index;


/*----------------------- create_index_script ------------------------------*/

procedure create_index_script(
  index_name      in varchar2,
  report          in out nocopy clob,
  prefname_prefix in varchar2 default null
)
is
  idx    driutl.index_rec;
  ixp    driutl.ixp_rec;
  l_oat_id number;
  prename varchar2(120);
  dummy   number;
  i       number;

  prefs  driutl.arr_table;
  pname  driutl.arr_table;
  pspref driutl.arr_table;

  buff   varchar2(500);
  basetable# number;

begin
  for i in 1..DRIOBJ.NUM_CLASS loop
    prefs(i) := null;
  end loop;

  initreport;
   
  -- get index meta-data
  idx := driutl.get_index(index_name);

  -- handle prefname prefix
  if (prefname_prefix is not null) then
    -- check length
    if (idx.idx_option like '%P%') then
      if (lengthb(prefname_prefix) > 21) then
        drue.push(DRIG.GU_LENGTH_ERROR, 'PREFNAME_PREFIX', 21);
        raise dr_def.textile_error;
      end if;
    else
      if (lengthb(prefname_prefix) > 25) then
        drue.push(DRIG.GU_LENGTH_ERROR, 'PREFNAME_PREFIX', 25);
        raise dr_def.textile_error;
      end if;
    end if;
    pv_pnpfx := upper(prefname_prefix);
  else
    pv_pnpfx := idx.idx_name;
  end if;
 
  -- handle indexing objects
  for c1 in (select /*+ORDERED*/ cla_id, cla_name, obj_id, obj_name
               from dr$index_object, dr$class, dr$object
              where cla_system = 'N'
                and ixo_cla_id = cla_id
                and ixo_cla_id = obj_cla_id
                and ixo_obj_id = obj_id
                and ixo_idx_id = idx.idx_id
              order by cla_id)
  loop
    -- skip certain classes for certain index types
    if (idx.idx_type = driddl.idx_type_context or
        idx.idx_type = driddl.idx_type_ctxrule or
        (idx.idx_type = driddl.idx_type_ctxcat and 
         c1.cla_id >= DRIOBJ.CLASS_LEXER))
    then
      scriptcp(idx, c1.cla_id, c1.obj_name, prename);
      if (pv_afterend is null) then
        prefs(c1.cla_id) := prename;
      else
        prefs(c1.cla_id) := 'CTXSYS.'||prename;
      end if;
      if (c1.cla_id = DRIOBJ.CLASS_LEXER and
          c1.obj_id = DRIOBJ.OBJ_MULTI_LEXER) then
        scriptend;
        report_multi_lexer(idx, prename);
      else
        report_index_values(idx, prename, c1.cla_id, c1.obj_id);
        scriptend;
      end if;
    end if;
  end loop;

  -- handle per-partition storage preferences
  if (idx.idx_option like '%P%') then

    -- look up oat_id for PART_SUB_STORAGE_ATTR
    select oat_id into l_oat_id from dr$object_attribute
     where oat_cla_id = DRIOBJ.CLASS_STORAGE
       and oat_obj_id = DRIOBJ.OBJ_BASIC_STORAGE
       and oat_name = 'PART_SUB_STORAGE_ATTR';
    i := 0;

    select idx_table# into basetable# from dr$index
     where idx_id = idx.idx_id;

    for c1 in (select /*+ORDERED*/ ixp_id, ixp_name 
                 from dr$index_partition ip, sys.tabpart$ tp
                where ixp_idx_id = idx.idx_id
                  and ixp_table_partition# = tp.obj#
                  and tp.bo# = basetable#
                order by tp.part#)
    loop
      prename := null;
      i := i + 1;

      -- see if there are per-partition storage attributes
      select count(*) into dummy from dr$index_value
       where ixv_idx_id = idx.idx_id
         and ixv_sub_group = c1.ixp_id
         and ixv_oat_id = l_oat_id;

      if (dummy > 0) then
        scriptcp(idx, DRIOBJ.CLASS_STORAGE, 'BASIC_STORAGE', prename, 
                 ltrim(to_char(c1.ixp_id,'0009')));
        report_index_sub_values(idx, prename, DRIOBJ.CLASS_STORAGE, 
                                l_oat_id, c1.ixp_id, 2);
        scriptend;
      end if;
      pspref(i) := prename;
      pname(i)  := c1.ixp_name;
      
    end loop;
  end if;

  -- start logging
  blankln;
  writeln('begin');
  writeln('  ctx_output.start_log('''||idx.idx_name||'_LOG'');');
  writeln('end;');
  writeln('/');
  blankln;

  -- write the create index statement
  writeln('create index "'||idx.idx_owner||'"."'||idx.idx_name||'" ');
  writeln('  on "'||idx.idx_table_owner||'"."'||idx.idx_table||'"("'||
                    idx.idx_text_name||'")');

  if (idx.idx_type = DRIDDL.IDX_TYPE_CONTEXT) then
    writeln('  indextype is ctxsys.context');
  elsif (idx.idx_type = DRIDDL.IDX_TYPE_CTXCAT) then
    writeln('  indextype is ctxsys.ctxcat');  
  elsif (idx.idx_type = DRIDDL.IDX_TYPE_CTXRULE) then
    writeln('  indextype is ctxsys.ctxrule');
  end if;

  writeln('  parameters(''');
  
  if (prefs(DRIOBJ.CLASS_DATASTORE) is not null) then
    writeln('    datastore       '||prefs(DRIOBJ.CLASS_DATASTORE));
  end if;
  if (prefs(DRIOBJ.CLASS_FILTER) is not null) then
    writeln('    filter          '||prefs(DRIOBJ.CLASS_FILTER));
  end if;
  if (prefs(DRIOBJ.CLASS_SECTION_GROUP) is not null) then
    writeln('    section group   '||prefs(DRIOBJ.CLASS_SECTION_GROUP));
  end if;
  if (prefs(DRIOBJ.CLASS_LEXER) is not null) then
    writeln('    lexer           '||prefs(DRIOBJ.CLASS_LEXER));
  end if;
  if (prefs(DRIOBJ.CLASS_WORDLIST) is not null) then
    writeln('    wordlist        '||prefs(DRIOBJ.CLASS_WORDLIST));
  end if;
  if (prefs(DRIOBJ.CLASS_STOPLIST) is not null) then
    writeln('    stoplist        '||prefs(DRIOBJ.CLASS_STOPLIST));
  end if;
  if (prefs(DRIOBJ.CLASS_STORAGE) is not null) then
    writeln('    storage         '||prefs(DRIOBJ.CLASS_STORAGE));
  end if;
  if (prefs(DRIOBJ.CLASS_INDEX_SET) is not null) then
    writeln('    index set       '||prefs(DRIOBJ.CLASS_INDEX_SET));
  end if;

  if (idx.idx_language_column is not null) then
    writeln('    language column "'||idx.idx_language_column||'"');
  end if;
  if (idx.idx_format_column is not null) then
    writeln('    format column   "'||idx.idx_format_column||'"');
  end if;
  if (idx.idx_charset_column is not null) then
    writeln('    charset column  "'||idx.idx_charset_column||'"');
  end if;

  writeln('  '')');

  -- partitions
  if (idx.idx_option like '%P%') then
    writeln('  local (');

    for i in 1..pname.count loop
      buff := '    partition "'||pname(i)||'"';

      if (pspref(i) is not null) then
        writeln(buff);
        buff := '      parameters (''storage '||pspref(i)||''')';
      end if;

      if (i != pname.count) then
        buff := buff || ',';
      end if;

      writeln(buff);

    end loop;
    writeln('  )');
  end if;

  writeln('/');

  -- end logging
  blankln;
  writeln('begin');
  writeln('  ctx_output.end_log;');
  writeln('end;');
  writeln('/');
  blankln;

  endreport(report);

exception
  when dr_def.textile_error then
    drue.raise;
  when others then
    drue.text_on_stack(sqlerrm, 'ctx_report.create_index_script');
    drue.raise;
end create_index_script;

/*--------------------- create_index_script (fn) -------------------------*/

function create_index_script(
  index_name      in varchar2,
  prefname_prefix in varchar2 default null
) return clob
is
  x clob;
begin
  dbms_lob.createtemporary(x, TRUE, DBMS_LOB.CALL);
  create_index_script(index_name, x, prefname_prefix);
  return x;  
end create_index_script;

/*--------------------------- index_size --------------------------------*/

procedure index_size(
  index_name in varchar2,
  report     in out nocopy clob,
  part_name  in varchar2 default null
) is
  idx driutl.index_rec;
  ixp driutl.ixp_rec;
  tka number := 0;
  tku number := 0;
  tba number := 0;
  tbu number := 0;
begin
  initreport;

  idx := driutl.get_index(index_name);

  if (part_name is not null) then
    ixp := driutl.get_ipartition(part_name, idx);
    desctitle('INDEX SIZE FOR '||idx.idx_owner||'.'||idx.idx_name,
              'INDEX PARTITION '||ixp.ixp_name);
    size_index_part(idx, ixp, tka, tku, tba, tbu);
  else
    desctitle('INDEX SIZE FOR '||idx.idx_owner||'.'||idx.idx_name);
    if (idx.idx_option like '%P%') then
      for c1 in (select /*+INDEX(ip drc$ixp_key)*/ ixp_id, ixp_name
                   from dr$index_partition ip
                  where ixp_idx_id = idx.idx_id
                  order by ixp_idx_id, ixp_id)
      loop
        ixp.ixp_id := c1.ixp_id; ixp.ixp_name := c1.ixp_name;
        desctitle('PARTITION '||ixp.ixp_name, sep=>h60);
        size_index_part(idx, ixp, tka, tku, tba, tbu);
      end loop;
    else
      size_index_part(idx, ixp, tka, tku, tba, tbu);
    end if;

    writeln('TOTALS FOR INDEX '||idx.idx_owner||'.'||idx.idx_name);
    writeln(h60);
    sizeln(null, 'TOTAL ', tka, tku, tba, tbu);    
    blankln;
  end if;

  endreport(report);
exception
  when dr_def.textile_error then
    drue.raise;
  when others then
    drue.text_on_stack(sqlerrm, 'ctx_report.index_size');
    drue.raise;
end index_size;

/*------------------------ index_size (fn) --------------------------------*/

function index_size(
  index_name  in varchar2,
  part_name   in varchar2 default null
) return clob
is
  x clob;
begin
  dbms_lob.createtemporary(x, TRUE, DBMS_LOB.CALL);
  index_size(index_name, x, part_name);
  return x;  
end index_size;


end ctx_report;
/
list 800 850
show errors


Rem 
Rem $Header: driutl.pkb 03-sep-01.23:09:17 ehuang Exp $ 
Rem 
Rem Copyright (c) Oracle Corporation 1991, 1996, 1997, 1998, 1999, 2000, 2001.  All Rights Reserved.
Rem  NAME
Rem    driutl.pkb - DRD Index services
Rem  DESCRIPTION
rem    DR ultilities package. called by all components
Rem  RETURNS
Rem 
Rem    NOTES
Rem      <other useful comments, qualifications, etc.>
Rem    MODIFIED   (MM/DD/YY)
Rem     ehuang     09/03/01 -  extend index_rec
Rem     gkaminag   07/27/01 -  rac name change
Rem     ehuang     05/29/01 -  bug 1799659
Rem     gkaminag   03/16/01 -  bug 1691651
Rem     yucheng    01/03/01 -  fix bug 1487693
Rem     gkaminag   10/23/00 -  allow up to 9999 partitions
Rem     gkaminag   08/22/00 -  move partition logic
Rem     gkaminag   08/15/00 -  add get_partition
Rem     yucheng    08/08/00 -  partition support
Rem     gkaminag   08/09/00 -  local domain partition support
Rem     gkaminag   04/12/00 -  adjust get_user for new index type
Rem     gkaminag   03/07/00 -  add idx_type to idx_record
Rem     gkaminag   11/01/99 -  multi stoplist
Rem     gkaminag   06/21/99 -  format and charset columns
Rem     gkaminag   06/09/99 -  language column in idx record
Rem     gkaminag   06/07/99 -  multi lexer
Rem     gkaminag   05/21/99 -  trigger prefix
Rem     ehuang     03/01/99 -  add make_pfx
Rem     gkaminag   02/15/99 -  move idx_has_p_table to drixtab
Rem     gkaminag   01/28/99 -  substring indexing
Rem     gkaminag   11/13/98 -  bug 758226
Rem     gkaminag   09/14/98 -  do not uppercase object names
Rem     gkaminag   09/02/98 -  add option to get_user to ignore anonymous block
Rem     gkaminag   08/13/98 -  add idxmem_to_number
Rem     syang      07/01/98 -  textile_error handler in mem_to_number
Rem     gkaminag   06/29/98 -  bug 683151
Rem     gkaminag   05/28/98 -  bug 675340
Rem     gkaminag   05/20/98 -  message cleanup
Rem     gkaminag   05/19/98 -  mem to number
Rem     gshank     05/12/98 -  Bug 633309 Handle nonstandard userids
Rem     gkaminag   05/11/98 -  using object id's
Rem     gkaminag   05/08/98 -  add acess_index
Rem     ehuang     05/08/98 -  get_index return all fields
Rem     gkaminag   04/13/98 -  remove debugging messages
Rem     ehuang     03/30/98 -  dr$policy->dr$index
Rem     ehuang     03/25/98 -  change ctx_access to driacc
Rem     gkaminag   03/24/98 -  section group changes
Rem     ehuang     03/23/98 -  minor call stack bug
Rem     gkaminag   02/23/98 -  bug 627135
Rem     jkud       01/28/98 -  add get_rowid
Rem     ymatsuda   08/19/97 -  add PICK_POLICY
Rem     dyu        10/20/97 -  Change CT_LEXICON_OERR to CT_LEXICON_FERR
Rem     gkaminag   09/24/97 -  add verify_lexicon
Rem     dyu        08/21/97 -  work around for 532862
Rem     ehuang     07/28/97 -  Bug 518206 - add is_ops
Rem     gkaminag   06/24/97 -  handle empty section groups
Rem     ehuang     06/04/97 -  Bg 478063 - add get_user
Rem     gkaminag   05/19/97 -  remove debugging messages
Rem     gkaminag   05/13/97 -  add get_dbid
Rem     ehuang     05/01/97 -  add validate_stmt
Rem     ehuang     04/28/97 -  add split
Rem     gkaminag   04/30/97 -  message change
Rem     ymatsuda   04/24/97 -  length check
Rem     gkaminag   04/17/97 -  add section count
Rem     ymatsuda   04/23/97 -  Bg482294
Rem     ymatsuda   04/22/97 -  dblink case sensitivity
Rem     ymatsuda   04/22/97 -  invalid char error
Rem     ymatsuda   04/09/97 -  add lock_table
Rem     ehuang     04/07/97 -  change list of invalid chars
Rem     ehuang     04/03/97 -  check invalid char in parsr_object_name
Rem     cbhavsar   02/18/97 -  Bug 451978
Rem     ymatsuda   02/14/97 -  bg445564
Rem     gkaminag   01/29/97 -  error processing from dbms_utility.name_tokenize
Rem     gkaminag   01/22/97 -  add quick test on get_policy
Rem     gkaminag   01/22/97 -  change how user_in_role is used
Rem     ymatsuda   12/18/96 -  owner of remote policy
Rem     ymatsuda   12/16/96 -  add dblink to parse_object_name
Rem     ymatsuda   12/06/96 -  add install_callback
Rem     syang      01/04/97 -  add pkey_toolong()
Rem     yucheng    11/12/96 -  Fix bug 396700.
Rem     gkaminag   03/04/96 -  Access control in get_policy
Rem     qtran      03/10/95 -  added genid function
Rem     qtran      10/19/94 -  Creation 

create or replace package body driutl as

  dbid number;

/*-------------------------------- get_utc --------------------------------*/
/*
  NAME
   get_utc - parse u.t.c name
  DESCRIPTION
   extracts username, tablename, and column name from a column spec 
   [user.]table.column
  NOTES
   a)  to modify to support [[[user].][table].]column. user can specify:
       1) user.table.column
       2) user..column  (this indicate it is a template index)
       3) table.column
       4) column
   b) name_tokenize checks identifier lengths.
  EXCEPTIONS
   none.
  RETURNS
    none
*/
procedure get_utc(spec varchar2, uname in out varchar2, tname in out varchar2,
 		  cname in out varchar2) is
  it_exists number;                 -- dummy variable
  l_uname   varchar2(30);
  l_tname   varchar2(30);
  l_cname   varchar2(30);
  l_dblink  varchar2(128);
  pos       binary_integer;
  invalid_char exception;
  pragma       exception_init(invalid_char, -911);
begin

  if spec is null then
    uname := get_user; 
    tname := NULL;
    cname := NULL;
    return;
  end if;

  begin
    dbms_utility.name_tokenize(spec, l_uname, l_tname, l_cname, l_dblink, pos);
    if pos <> lengthb(spec) then
      raise invalid_char;
    end if;
  exception
    when others then
      drue.text_on_stack(sqlerrm);
      drue.push(DRIG.DL_ILL_COL_SPEC, upper(spec));
      raise dr_def.textile_error;
  end;

  IF l_dblink is not null THEN
    drue.push(DRIG.DL_ILL_COL_SPEC, upper(spec));
    raise dr_def.textile_error;
  END IF;

  if l_tname is null then
    cname := l_uname;
    tname := NULL;
    uname := get_user; 
  elsif l_cname is null then
    cname := l_tname;
    tname := l_uname;
    uname := get_user; 
  else
    uname := l_uname;
    tname := l_tname;
    cname := l_cname;
  end if;

exception
  when dr_def.textile_error then
      raise dr_def.textile_error;
  when others then
      drue.text_on_stack(sqlerrm);
      raise dr_def.textile_error;
end get_utc;

/*-------------------------------- get_dbid --------------------------------*/
/*
  NAME
   get_dbid - get database identifier
  DESCRIPTION
   returns a number which is unique to the database (in OPS, there are
   multiple databases sharing a disk)
  NOTES
  EXCEPTIONS
   none.
  RETURNS
    none
*/
function get_dbid return number
is 
begin
  if dbid is null then
    select id1 into dbid 
      from v$resource 
     where type = 'RT' 
       and id2 = 0 
       and rownum = 1; 
  end if;
  if (dbid is null) then
    dbid := 1;
  end if;
  return dbid;
exception 
  when others then
    drue.text_on_stack(sqlerrm);
    drue.text_on_stack('in DRIUTL.GET_DBID');
    raise dr_def.textile_error;
end get_dbid;


/*--------------------------- parse_object_name ----------------------------*/
/*
  NAME
   parse_object_name - parse object name user.name@dblink
  DESCRIPTION
   extracts username, name from a object spec 
   [user.]objectname[@dblink]
  NOTES
   dblink is fully qualified.
   name_tokenize checks identifier lengths.
  EXCEPTIONS
   none.
  RETURNS
    none
*/
procedure parse_object_name(spec varchar2, uname in out varchar2, 
                        oname in out varchar2)
is
 dblink varchar2(200);
begin
 parse_object_name(spec, uname, oname, dblink);
 if dblink is not null then
   drue.push(DRIG.DL_ILL_POL_NAME, upper(spec));
   raise dr_def.textile_error;
 end if;
end;

procedure parse_object_name(spec varchar2, uname in out varchar2, 
                            oname in out varchar2, dblink in out varchar2)
is
  l_uname      varchar2(30);
  l_oname      varchar2(30);
  l_dblink     varchar2(128);
  dummy        varchar2(30);
  pos          binary_integer;
  invalid_char exception;
  pragma       exception_init(invalid_char, -911);
begin

  if spec is null then
    uname := NULL;
    oname := NULL;
    dblink := NULL;
    return;
  end if;

  begin
    dbms_utility.name_tokenize(spec, l_uname, l_oname, dummy, l_dblink, pos);
    if pos <> lengthb(spec) then
      raise invalid_char;
    end if;
  exception
    when others then
      drue.text_on_stack(sqlerrm);
      drue.push(DRIG.DL_ILL_POL_NAME);
      raise dr_def.textile_error;
  end;
    
  if dummy is not null then
    drue.push(DRIG.DL_ILL_POL_NAME);
    raise dr_def.textile_error;
  end if;

  if l_dblink is not null and instr(l_dblink,'.') = 0 then
    select l_dblink||'.'||value into l_dblink from v$parameter
    where name = 'db_domain';

    if lengthb(l_dblink) > 128 THEN
      -- TODO: better error message
      drue.push(DRIG.DL_OBJ_NAME_TOO_LONG);
      raise dr_def.textile_error;
    end if;
  end if;

  if l_oname is null then
    l_oname := l_uname;
    l_uname := get_user; 

    if l_dblink is not null then
      -- get remote user name
      for r in (select username from dba_db_links
                where db_link = upper(l_dblink) and
                      owner in (l_uname, 'PUBLIC')
                order by decode(owner,'PUBLIC',1,0))
      loop
        l_uname := nvl(r.username,l_uname);
        exit;
      end loop;
    end if;
  end if;

  uname := l_uname;
  oname := l_oname;
  dblink := l_dblink;

exception
  when dr_def.textile_error then
      raise dr_def.textile_error;
  when others then
      drue.text_on_stack(sqlerrm);
      raise dr_def.textile_error;

end parse_object_name;

/*----------------------------- split_list --------------------------------*/
/*
  NAME
    split_list - 

  DESCRIPTION
    A list can be contiguous or non-contiguous.

    list=1,500    contiguous=1 is a contig. list
    list=1,4,5,6  contiguous=0 is a non-contig list
    
    if we required 20 in the first list, it will be splited into:
      lower_list=1,20
      upper_list=21,500

    if we required 2 in the second list, it will be splited into:
      lower_list=1,4
      upper_list=5,6
  ARGUMENTS
   list          (in)  the list 
   contiguous    (in)  1= contig. 0=non-contig
   size_required (in)  list length
   lower_list    (out) lower list after splited
   upper_list    (out) upper list after splited

  NOTES
    
       
  EXCEPTIONS

  RETURNS
    none
*/
procedure split_list(
   list           in varchar2, 
   contiguous     in  number,
   size_required  in number,
   lower_list     out varchar2,
   upper_list     out varchar2) 
is
   lower_ids   dr_def.id_tab;
   upper_ids   dr_def.id_tab;
   nextpos     BINARY_INTEGER;
   comma_pos   BINARY_INTEGER;
   oldpos      BINARY_INTEGER;
begin

  if contiguous = 1 then
     -- e.g. (1,50000) -> (1,300), (301,5000)
     -- drdbg.print('found contiguous range ...');
     comma_pos :=  instr(list, ',', -1, 1);
     lower_ids(1) := substr(list, 1, comma_pos-1);
     lower_ids(2) := substr(list, comma_pos+1);

     -- upper_list := lower_list;
     upper_ids(2) := lower_ids(2);
     lower_ids(2) := lower_ids(1) + size_required - 1;
     upper_ids(1) := lower_ids(2) + 1;

     -- write to the output variables
     lower_list := lower_ids(1) ||','||lower_ids(2);
     upper_list := upper_ids(1) ||','||upper_ids(2);

  else
     -- e.g. (1,2,3,4,7,8,11,23) -> (1,2,3,4), (7,8,11,23)
     -- scan the list until the required number of ids have been found
     nextpos  := 1;
     oldpos := nextpos;    
     for j in 1..size_required loop
       nextpos := INSTR(list, ',', oldpos, 1 );
       oldpos := nextpos + 1;                        
     end loop;
     lower_list := substr(list, 1, oldpos - 1);
     upper_list := substr(list, oldpos);
  end if;

end;

/*-------------------------------- split -----------------------------------*/
/*
  NAME
    split

  DESCRIPTION
    Takes a list of values separated by a delimiter and return an
    array of the value.  A delimiter character preceded by a 
    backslash will be treated as part of the value instead.
 
  ARGUMENTS
    vlist      -    list of values                                           
    delimiter  -    the delimiter, one character only                         
    varr       -    array of values

  NOTES
  
  EXCEPTIONS
  
  RETURNS
*/
PROCEDURE split(                                                            
  vlist       in      varchar2                                                
, delimiter   in      varchar2                                          
, varr        in out  arr_table                                              
) IS                          
  beginpos     number := 1;                                        
  startpos     number := 1;                                                   
  foundpos     number := 0;                                                    
  counter      number := 0;                                                    
BEGIN                                                                          
  beginpos := 1;                                                               
  loop                                                                         
      foundpos := INSTR(vlist, delimiter, startpos, 1);                        
      exit when foundpos = 0;                                                  

      -- if the delimter is preceded by a \, it's part of the string           
      if (substr(vlist, foundpos -1, 1) != '\') then                           
         counter := counter + 1;                                               
         varr(counter) := substr(vlist, beginpos, foundpos - beginpos);        

         -- replace \delimiter with just delimiter    
         varr(counter) := replace(varr(counter), '\'||delimiter, delimiter); 

         beginpos := foundpos + 1;
      end if;
   
      startpos := foundpos + 1;                                              
  end loop;                                                                    

  -- check last chunk                                                          
  if length(substr(vlist,beginpos)) > 0 then                                   
     counter := counter + 1;                                                   
     varr(counter) := substr(vlist, beginpos);                                 
     varr(counter) := replace(varr(counter),'\'||delimiter,                    
			    		          delimiter);                           
  end if;                    
                                                  
EXCEPTION                                                                      
  when others then                                                             
    drue.text_on_stack(sqlerrm);                                               
    raise dr_def.textile_error;                                                
END split;                         

/*----------------------------- get_index_id ----------------------------*/
/*
  NAME
    get_index_id - get index id of for the index with name specified in 
    'index_name'.

  DESCRIPTION

  ARGUMENTS  
    index_name    - index name 
    index_id      - index  id
  NOTES
    
       
  EXCEPTIONS

  RETURNS
    none
*/
procedure get_index_id(index_name in varchar2, index_id out integer)
is
  l_pol   index_rec;
begin

  index_id := null;

  l_pol := get_index(index_name);

  index_id := l_pol.idx_id;

exception
  when dr_def.textile_error then
      raise dr_def.textile_error;
  when others then
      drue.text_on_stack(sqlerrm);
      raise dr_def.textile_error;
end get_index_id;


/*----------------------------- get_index ----------------------------*/
/*
  NAME
    get_index - return the policy for given index_name

  DESCRIPTION

  ARGUMENTS
    index_name     - index name 
  NOTES
    
       
  EXCEPTIONS

  RETURNS
    none
*/
function get_index(index_name in varchar2) return index_rec is

  l_name     varchar2(60);
  l_table    varchar2(30);
  l_owner    varchar2(60);
  l_idx      index_rec;
  lv_datasrc varchar2(255);
  lv_index_name varchar2(255) := index_name;
  lv_user    varchar2(65) := get_user;  -- Bug 478063
  l_owner#   number;
begin

  -- required to resolve synonyms on policies 

  if (substr(lv_index_name, 1, 1) != '"') then
    lv_index_name := upper(lv_index_name);
  end if;

  -- bug 478063
  if (not driacc.can(lv_user, 'CONTAINS', lv_index_name)) then
    raise no_data_found;
  end if;

  parse_object_name(lv_index_name, l_owner, l_name);
  l_owner# := driutl.get_user_id(l_owner);

    select /*+ ORDERED USE_NL(o) */ idx_id, idx_type, l_owner, idx_name, 
           u.name, o.name,
           idx_key_name, idx_key_type, 
           idx_text_name, idx_text_type, idx_text_length,
           idx_docid_count, idx_status, 
           idx_version, idx_nextid, 
           idx_language_column, idx_format_column, 
           idx_charset_column, idx_option,
           idx_opt_token, idx_opt_type, idx_opt_count
     into  l_idx.idx_id, l_idx.idx_type, l_idx.idx_owner, l_idx.idx_name, 
           l_idx.idx_table_owner, l_idx.idx_table,
           l_idx.idx_key_name, l_idx.idx_key_type, 
           l_idx.idx_text_name, l_idx.idx_text_type, l_idx.idx_text_length,
           l_idx.idx_docid_count, l_idx.idx_status, 
           l_idx.idx_version, l_idx.idx_nextid, 
           l_idx.idx_language_column, l_idx.idx_format_column,
           l_idx.idx_charset_column, l_idx.idx_option,
           l_idx.idx_opt_token, l_idx.idx_opt_type, l_idx.idx_opt_count
     from dr$index, sys.user$ u, sys.obj$ o
    where idx_name = l_name
     and  idx_owner# = l_owner#
     and  idx_table_owner# = u.user#
     and  idx_table# = o.obj#;

    if (l_idx.idx_table != 'TEMPLATE_POLICY' and 
        lv_user != l_idx.idx_owner and
        lv_user != 'CTXSYS') then

      -- index does not exist if user cannot select on datasource.
      lv_datasrc := '"' || l_idx.idx_table_owner || '"."' 
                        || l_idx.idx_table || '"';

      -- bug 478063
      if (not driacc.can(lv_user, 'SELECT', lv_datasrc)) THEN
         drue.push(DRIG.DL_POLICY_NOTXIST, upper(index_name));
	 raise dr_def.textile_error;
      end if;

    end if;

    return l_idx;

exception
    when no_data_found then
      drue.push(DRIG.DL_POLICY_NOTXIST, upper(index_name));
      raise dr_def.textile_error;
    when dr_def.textile_error then
      raise dr_def.textile_error;
    when others then
      drue.text_on_stack(sqlerrm);
      raise dr_def.textile_error;
end get_index;
--
--
function get_index_by_id(index_id in number) return index_rec is
  l_idx      index_rec; 
  lv_datasrc varchar2(255);
begin

    select /*+ ORDERED USE_NL(o) */ idx_id, idx_type, u.name, idx_name, 
           u2.name, o.name,
           idx_key_name, idx_key_type, 
           idx_text_name, idx_text_type, idx_text_length,
           idx_docid_count, idx_status, 
           idx_version, idx_nextid, 
           idx_language_column, idx_format_column, 
           idx_charset_column, idx_option,
           idx_opt_token, idx_opt_type, idx_opt_count
     into  l_idx.idx_id, l_idx.idx_type, l_idx.idx_owner, l_idx.idx_name, 
           l_idx.idx_table_owner, l_idx.idx_table,
           l_idx.idx_key_name, l_idx.idx_key_type, 
           l_idx.idx_text_name, l_idx.idx_text_type, l_idx.idx_text_length,
           l_idx.idx_docid_count, l_idx.idx_status, 
           l_idx.idx_version, l_idx.idx_nextid, 
           l_idx.idx_language_column, l_idx.idx_format_column,
           l_idx.idx_charset_column, l_idx.idx_option,
           l_idx.idx_opt_token, l_idx.idx_opt_type, l_idx.idx_opt_count
     from dr$index, sys.user$ u, sys.user$ u2, sys.obj$ o
    where idx_id = index_id
     and  idx_owner# = u.user#
     and  idx_table_owner# = u2.user#
     and  idx_table# = o.obj#;

    -- select checking is bypassed in index by id retrieval.

    return l_idx;

exception
    when no_data_found then
      drue.push(DRIG.DL_POLICY_NOTXIST, to_char(index_id));
      raise dr_def.textile_error;
    when dr_def.textile_error then
      raise dr_def.textile_error;
    when others then
      drue.text_on_stack(sqlerrm);
      raise dr_def.textile_error;
end get_index_by_id;

/*----------------------------- access_idx ---------------------------------*/

procedure access_idx(p_idx_id in number)
is
  l_status             varchar2(16);
  l_ver                number;
  l_name               varchar2(30);
begin

  begin
    select idx_name, idx_status, idx_version 	
      into l_name, l_status, l_ver 
      from dr$index
     where idx_id = p_idx_id;
  exception
    when no_data_found then
      drue.push(DRIG.DL_INDEX_NOT_FOUND, l_name);
      raise dr_def.textile_error;
  end;

  -- Check index version

  if (l_ver != DRIDDL.VERSION_LATEST) then
    drue.push(DRIG.DL_TEXT_INDEX_OBS, l_name);
    raise dr_def.textile_error;
  end if;

  -- Check that the index is in INDEXED state 

  if (l_status != driddl.STATE_INDEXED) then
    drue.push(DRIG.DL_INDEX_NOT_FOUND, l_name);
    raise dr_def.textile_error;
  end if;

exception
when dr_def.textile_error then
  raise dr_def.textile_error;
when others then
  drue.text_on_stack(sqlerrm);
  raise dr_def.textile_error;
end;

/*---------------------------------- genid ---------------------------------*/
/*
  NAME
    genid - generate an TexTile dict
  DESCRIPTION
    TexTile dict. id number is used to assigned to POLICY or PREFERENCE.

  ARGUMENTS
    None
  NOTES
           
  EXCEPTIONS

  RETURNS
    id number
*/
function genid return number
is
  id   number;
begin
  select  dr_id_seq.nextval into id from dual;
  return id;
exception
  when others then
    drue.text_on_stack(sqlerrm);
    raise dr_def.textile_error;
end;

/*---------------------------- pkey_toolong ---------------------------------*/
/*
  NAME
    pkey_toolong - check a length of a given primary key is too long or not
  DESCRIPTION
    as pkey can be an encoded composite pkey string, the checking need to be
    done on the overall length and the individual textkey length
 
  ARGUMENTS
    pk -- primary key string
  NOTES
 
  EXCEPTIONS
 
  RETURNS
    toolong boolean
*/
function pkey_toolong(pk in varchar2) return boolean
is
  foundpos   number;
  beginpos   number;
begin
  -- check overall length first
  if (LENGTHB(pk) > 256) then
     return TRUE;
  end if;

  -- check individual key length
  beginpos := 1;
  loop
      foundpos := INSTR(pk, ',', beginpos, 1 );
      exit when foundpos = 0;
      if (LENGTHB(SUBSTR(pk,beginpos,foundpos-1))>64) then
        return TRUE;
      end if;
      beginpos := foundpos + 1;
  end loop;
  if (LENGTHB(SUBSTR(pk,beginpos)) > 64) then
    return TRUE;
  else
    return FALSE;
  end if;

exception
  when others then
    drue.text_on_stack(sqlerrm);
    raise dr_def.textile_error;
end;

/*---------------------------- get_user ------------------------------*/
/*
  NAME
    get_user - get the effective user

  DESCRIPTION
    see dr0utl.pkh

  ARGUMENTS
    
  NOTES
           
  EXCEPTIONS
*/
function get_user(ignore_anon in boolean default FALSE) return varchar2
is
  call_stack  varchar2(10000);
  n           number;
  found_stack BOOLEAN := FALSE;
  line        varchar2(2000);
  owner       varchar2(100);
  name        varchar2(100);
begin
  call_stack := dbms_utility.format_call_stack;

  if (call_stack is null) then 
    return USER; 
  end if;
  
  loop
    n := instr(call_stack, chr(10));
    exit when (n is NULL or n = 0);

    line := substr(call_stack, 1, n-1);
    call_stack := substr(call_stack, n+1);

    if (not found_stack) then
       if (line like '%handle%number%name%') then
          found_stack := TRUE;
       end if;
       goto next_loop;
    end if;

    -- format is like this:
    -- 4008be570       13     function....
    -- inner ltrim shaves off the SGA object handle
    -- outer ltrim shaves off the line number and the spaces
     
    -- bug 627135: length of sga address part is not
    -- the same from platform to platform.

    -- bug 675340: some platforms have spaces before the address 
    -- part, so a third, innermost ltrim is needed

    line := ltrim(ltrim(ltrim(line),'0123456789abcdefABCDEFxX'),' 0123456789');

    if (line like 'pr%') then
       n := length( 'procedure ');
    elsif (line like 'fun%' ) then
       n := length( 'function ');
    elsif (line like 'package body%') then
       n := length( 'package body ');     
    elsif (line like 'pack%') then
       n := length( 'package '); 
    elsif (line like 'anon%') then
       goto next_loop;
    else                        -- trigger line has just OWNER.TRIGGERNAME
       n := 1;
    end if;

    line := substr(line, n);

    -- at this point, line is of the form OWNER.SOMENAME

    n := instr(line, '.');
    owner := ltrim(rtrim(substr(line, 1, n-1)));
    name  := ltrim(rtrim(substr(line, n+1)));

    if (owner != 'CTXSYS') then
      if (owner = 'SYS' and name in ('DBMS_SYS_SQL','DBMS_SQL')) then
        goto next_loop;
      end if;
      return owner;
    elsif (name not like 'DR%' and name not like 'CTX_%' and
           name not like '%INDEXMETHODS') then
      return owner;
    end if;

    <<next_loop>>
    null;

  end loop;

  -- if at this point, it is an anonymous block of some kind
  -- so should return USER

  return USER;

exception
  when others then
    drue.text_on_stack(sqlerrm);
    drue.raise;
end get_user;

/*---------------------------- get_user_id ---------------------------*/

function get_user_id(p_username in varchar2) return number
is
  ret number;
  l_username varchar2(30) := upper(p_username);
begin
  select user# into ret 
    from sys.user$
   where name = l_username;
  return ret;
exception
  when no_data_found then
    drue.push(DRIG.DL_USER_NOTXIST, l_username);
    raise dr_def.textile_error;
  when others then
    drue.text_on_stack(sqlerrm);
    raise dr_def.textile_error;
end get_user_id;

/*---------------------------- get_obj_id ---------------------------*/

function get_obj_id(p_user_name in varchar2, p_object_name in varchar2,
                    p_partition_name in varchar2 default NULL) 
return number
is
  ret number;
  l_uname    varchar2(30) := rtrim(ltrim(p_user_name, '"'), '"');
  l_tname    varchar2(30) := rtrim(ltrim(p_object_name,'"'),'"');
  l_pname    varchar2(30);
begin

  if (p_partition_name is not NULL) then
    l_pname := rtrim(ltrim(p_partition_name,'"'),'"');

    select object_id into ret
      from dba_objects
     where object_type = 'TABLE PARTITION'
       and object_name = l_tname
       and subobject_name = l_pname
       and owner = l_uname;
  else

    select object_id into ret
      from dba_objects
     where object_type = 'TABLE'
       and object_name = l_tname
       and owner = l_uname;

  end if;

  return ret;
exception
-- TODO partition not exist
  when no_data_found then
    drue.push(DRIG.DL_TABLE_NOTXIST, l_tname);
    raise dr_def.textile_error;
  when others then
    drue.text_on_stack(sqlerrm);
    raise dr_def.textile_error;
end get_obj_id;

/*---------------------------- get_ipartition -----------------------------*/

function get_ipartition(part_name in varchar2, idx in index_rec) 
return ixp_rec
is
  l_ixp   ixp_rec;
  l_owner varchar2(30);
  l_name  varchar2(30);
begin

  if (part_name is not null) then
    parse_object_name(part_name, l_owner, l_name);
  end if;

  if (idx.idx_option like '%P%') then

    if (part_name is null) then
      drue.push(DRIG.PT_NO_PART_NAME);
      raise dr_def.textile_error;
    end if;

    select /*+ ORDERED USE_NL(o) */ 
         ixp_id, ixp_name, ixp_idx_id, o.subname, 
         ixp_docid_count, ixp_status, ixp_nextid,
         ixp_opt_token, ixp_opt_type, ixp_opt_count
    into l_ixp.ixp_id, l_ixp.ixp_name, l_ixp.ixp_idx_id, 
         l_ixp.ixp_table_partition, l_ixp.ixp_docid_count,
         l_ixp.ixp_status, l_ixp.ixp_nextid,
         l_ixp.ixp_opt_token, l_ixp.ixp_opt_type, l_ixp.ixp_opt_count
    from dr$index_partition, sys.obj$ o
   where ixp_idx_id = idx.idx_id
     and ixp_name = l_name
     and ixp_table_partition# = o.obj#;

  else

    if (part_name is not null) then    
      drue.push(DRIG.PT_NOT_PART_IDX);
      raise dr_def.textile_error;
    end if;

    l_ixp.ixp_id := 0;
    l_ixp.ixp_name := null;

  end if;

  return l_ixp;

exception
    when no_data_found then
      drue.push(DRIG.PT_PART_NOTXIST, l_name);
      raise dr_def.textile_error;
    when dr_def.textile_error then
      raise dr_def.textile_error;
    when others then
      drue.text_on_stack(sqlerrm, 'driutl.get_ipartition');
      raise dr_def.textile_error;
end get_ipartition;

/*------------------------- get_ipartition_by_id --------------------------*/

function get_ipartition_by_id(ixpid in number, idxid in number) 
return ixp_rec
is
  l_ixp   ixp_rec;
begin

  select /*+ ORDERED USE_NL(o) */ 
         ixp_id, ixp_name, ixp_idx_id, o.subname, 
         ixp_docid_count, ixp_status, ixp_nextid,
         ixp_opt_token, ixp_opt_type, ixp_opt_count
    into l_ixp.ixp_id, l_ixp.ixp_name, l_ixp.ixp_idx_id, 
         l_ixp.ixp_table_partition, l_ixp.ixp_docid_count,
         l_ixp.ixp_status, l_ixp.ixp_nextid,
         l_ixp.ixp_opt_token, l_ixp.ixp_opt_type, l_ixp.ixp_opt_count
    from dr$index_partition, sys.obj$ o
   where ixp_idx_id = idxid
     and ixp_id = ixpid
     and ixp_table_partition# = o.obj#;

  return l_ixp;

exception
    when no_data_found then
      drue.push(DRIG.PT_PART_NOTXIST, to_char(ixpid));
      raise dr_def.textile_error;
    when dr_def.textile_error then
      raise dr_def.textile_error;
    when others then
      drue.text_on_stack(sqlerrm, 'driutl.get_ipartition_by_id');
      raise dr_def.textile_error;
end get_ipartition_by_id;

/*------------------------- get_ipartition_id ----------------------------*/

function get_ipartition_id(partition_name in varchar2, 
                           idxid          in number)
return number
is
  ret      number;
  l_name  varchar2(30) := ltrim(rtrim(partition_name, '"'),'"');
begin

  select ixp_id into ret
    from dr$index_partition
   where ixp_idx_id = idxid
     and ixp_name = l_name;

  return ret;
exception
  when no_data_found then
    drue.push(DRIG.PT_PART_NOTXIST, l_name);
    raise dr_def.textile_error;
  when others then
    drue.text_on_stack(sqlerrm, 'driutl.get_ipartition_id');
    raise dr_def.textile_error;
end get_ipartition_id;

/*---------------------------- is_ops ------------------------------*/
/*
  NAME
    is_ops

  DESCRIPTION
    returns TRUE when running in parallel server mode, FALSE otherwise
  ARGUMENTS
    
  NOTES
           
  EXCEPTIONS
*/
function is_ops return boolean
is
begin
  return dbms_utility.is_cluster_database;
end is_ops;


/*---------------------------- mem_to_number --------------------------*/

function mem_to_number(memstring in varchar2, ulimit in number) return number
is
  l_mem     number;
  l_mod     number := 1;
  l_memstr  varchar2(30) := rtrim(ltrim(upper(memstring)));
begin

  if (l_memstr like '%M') then

    l_mod := 1024 * 1024;
    l_memstr := rtrim(l_memstr, 'M ');

  elsif (l_memstr like '%K') then

    l_mod := 1024;
    l_memstr := rtrim(l_memstr, 'K ');

  elsif (l_memstr like '%G') then

    l_mod := 1024 * 1024 * 1024;
    l_memstr := rtrim(l_memstr, 'G ');

  end if;

  l_mem := to_number(l_memstr) * l_mod;

  if (l_mem < power(2,10)  or l_mem > ulimit) then
    drue.push(DRIG.PF_MEM_RANGE, power(2,10), ulimit);
    raise dr_def.textile_error;
  end if;

  return l_mem;
  
exception
  when dr_def.textile_error then
      raise dr_def.textile_error;
  when value_error then
    drue.push(DRIG.PF_INVALID_MEM_STR, memstring);
    raise dr_def.textile_error;
  when others then 
    drue.text_on_stack(sqlerrm);
    raise dr_def.textile_error;
end mem_to_number;

/*---------------------------- idxmem_to_number --------------------------*/

function idxmem_to_number(memstring in varchar2) return number
is
  l_mem number;
  l_max number;
begin

  if (memstring is null) then
    select to_number(par_value) into l_mem
      from dr$parameter where par_name = 'DEFAULT_INDEX_MEMORY';
  else
    select to_number(par_value) into l_max
      from dr$parameter where par_name = 'MAX_INDEX_MEMORY';
    l_mem := mem_to_number(memstring, l_max);
  end if;

  return nvl(l_mem, 12 * power(2, 10));

exception
  when dr_def.textile_error then
    raise dr_def.textile_error;
  when others then 
    drue.text_on_stack(sqlerrm);
    raise dr_def.textile_error;
end idxmem_to_number;


FUNCTION make_pfx (idx_owner in varchar2, idx_name in varchar2,
                   pfx_type  in varchar2 default '$', 
                   part_id   in number default null) 
return varchar2 
is
begin
  if (part_id is null or part_id = 0) then
    if (idx_owner is null) then
      return '"DR$'||ltrim(rtrim(idx_name,'"'),'"')||pfx_type;
    else
      return '"'||ltrim(rtrim(idx_owner,'"'),'"')||'".'||
             '"DR$'||ltrim(rtrim(idx_name,'"'),'"')||pfx_type;
    end if;
  else
    if (idx_owner is null) then
      return '"DR#'||ltrim(rtrim(idx_name,'"'),'"')||
             ltrim(to_char(part_id,'0000'))||pfx_type;
    else
      return '"'||ltrim(rtrim(idx_owner,'"'),'"')||'".'||
             '"DR#'||ltrim(rtrim(idx_name,'"'),'"')||
             ltrim(to_char(part_id,'0000'))||pfx_type;
    end if;
  end if;
end make_pfx;

/*--------------------------- check_language -----------------------------*/

FUNCTION check_language (
  lang     in  varchar2,
  nls_lang out varchar2,
  nls_abb  out varchar2,
  def_ok   in  boolean default TRUE
) return boolean is
  l_lang varchar2(30) := upper(lang);
  valid  boolean;
begin
  valid := true;

  if (l_lang = 'DEFAULT' and def_ok) then
    nls_lang := 'DEFAULT';
    nls_abb  := '00';
  elsif (l_lang = 'AMERICAN' or l_lang = 'US') then
    nls_lang := 'AMERICAN';
    nls_abb  := 'US';
  elsif (l_lang = 'ARABIC' or l_lang = 'AR') then
    nls_lang := 'ARABIC';
    nls_abb  := 'AR';
  elsif (l_lang = 'BENGALI' or l_lang = 'BN') then
    nls_lang := 'BENGALI';
    nls_abb  := 'BN';
  elsif (l_lang = 'BRAZILIAN PORTUGUESE' or l_lang = 'PTB') then
    nls_lang := 'BRAZILIAN PORTUGUESE';
    nls_abb  := 'PTB';
  elsif (l_lang = 'BULGARIAN' or l_lang = 'BG') then
    nls_lang := 'BULGARIAN';
    nls_abb  := 'BG';
  elsif (l_lang = 'CANADIAN FRENCH' or l_lang = 'FRC') then
    nls_lang := 'CANADIAN FRENCH';
    nls_abb  := 'FRC';
  elsif (l_lang = 'CATALAN' or l_lang = 'CA') then
    nls_lang := 'CATALAN';
    nls_abb  := 'CA';
  elsif (l_lang = 'CROATIAN' or l_lang = 'HR') then
    nls_lang := 'CROATIAN';
    nls_abb  := 'HR';
  elsif (l_lang = 'CZECH' or l_lang = 'CS') then
    nls_lang := 'CZECH';
    nls_abb  := 'CS';
  elsif (l_lang = 'DANISH' or l_lang = 'DK') then
    nls_lang := 'DANISH';
    nls_abb  := 'DK';
  elsif (l_lang = 'DUTCH' or l_lang = 'NL') then
    nls_lang := 'DUTCH';
    nls_abb  := 'NL';
  elsif (l_lang = 'EGYPTIAN' or l_lang = 'EG') then
    nls_lang := 'EGYPTIAN';
    nls_abb  := 'EG';
  elsif (l_lang = 'ENGLISH' or l_lang = 'GB') then
    nls_lang := 'ENGLISH';
    nls_abb  := 'GB';
  elsif (l_lang = 'ESTONIAN' or l_lang = 'ET') then
    nls_lang := 'ESTONIAN';
    nls_abb  := 'ET';
  elsif (l_lang = 'FINNISH' or l_lang = 'SF') then
    nls_lang := 'FINNISH';
    nls_abb  := 'SF';
  elsif (l_lang = 'FRENCH' or l_lang = 'F') then
    nls_lang := 'FRENCH';
    nls_abb  := 'F';
  elsif (l_lang = 'GERMAN DIN' or l_lang = 'DIN') then
    nls_lang := 'GERMAN DIN';
    nls_abb  := 'DIN';
  elsif (l_lang = 'GERMAN' or l_lang = 'D') then
    nls_lang := 'GERMAN';
    nls_abb  := 'D';
  elsif (l_lang = 'GREEK' or l_lang = 'EL') then
    nls_lang := 'GREEK';
    nls_abb  := 'EL';
  elsif (l_lang = 'HEBREW' or l_lang = 'IW') then
    nls_lang := 'HEBREW';
    nls_abb  := 'IW';
  elsif (l_lang = 'HUNGARIAN' or l_lang = 'HU') then
    nls_lang := 'HUNGARIAN';
    nls_abb  := 'HU';
  elsif (l_lang = 'ICELANDIC' or l_lang = 'IS') then
    nls_lang := 'ICELANDIC';
    nls_abb  := 'IS';
  elsif (l_lang = 'INDONESIAN' or l_lang = 'IN') then
    nls_lang := 'INDONESIAN';
    nls_abb  := 'IN';
  elsif (l_lang = 'ITALIAN' or l_lang = 'I') then
    nls_lang := 'ITALIAN';
    nls_abb  := 'I';
  elsif (l_lang = 'JAPANESE' or l_lang = 'JA') then
    nls_lang := 'JAPANESE';
    nls_abb  := 'JA';
  elsif (l_lang = 'KOREAN' or l_lang = 'KO') then
    nls_lang := 'KOREAN';
    nls_abb  := 'KO';
  elsif (l_lang = 'LATIN AMERICAN SPANISH' or l_lang = 'ESA') then
    nls_lang := 'LATIN AMERICAN SPANISH';
    nls_abb  := 'ESA';
  elsif (l_lang = 'LATVIAN' or l_lang = 'LV') then
    nls_lang := 'LATVIAN';
    nls_abb  := 'LV';
  elsif (l_lang = 'LITHUANIAN' or l_lang = 'LT') then
    nls_lang := 'LITHUANIAN';
    nls_abb  := 'LT';
  elsif (l_lang = 'MALAY' or l_lang = 'MS') then
    nls_lang := 'MALAY';
    nls_abb  := 'MS';
  elsif (l_lang = 'MEXICAN SPANISH' or l_lang = 'ESM') then
    nls_lang := 'MEXICAN SPANISH';
    nls_abb  := 'ESM';
  elsif (l_lang = 'NORWEGIAN' or l_lang = 'N') then
    nls_lang := 'NORWEGIAN';
    nls_abb  := 'N';
  elsif (l_lang = 'POLISH' or l_lang = 'PL') then
    nls_lang := 'POLISH';
    nls_abb  := 'PL';
  elsif (l_lang = 'PORTUGUESE' or l_lang = 'PT') then
    nls_lang := 'PORTUGUESE';
    nls_abb  := 'PT';
  elsif (l_lang = 'ROMANIAN' or l_lang = 'RO') then
    nls_lang := 'ROMANIAN';
    nls_abb  := 'RO';
  elsif (l_lang = 'RUSSIAN' or l_lang = 'RU') then
    nls_lang := 'RUSSIAN';
    nls_abb  := 'RU';
  elsif (l_lang = 'SIMPLIFIED CHINESE' or l_lang = 'ZHS') then
    nls_lang := 'SIMPLIFIED CHINESE';
    nls_abb  := 'ZHS';
  elsif (l_lang = 'SLOVAK' or l_lang = 'SK') then
    nls_lang := 'SLOVAK';
    nls_abb  := 'SK';
  elsif (l_lang = 'SLOVENIAN' or l_lang = 'SL') then
    nls_lang := 'SLOVENIAN';
    nls_abb  := 'SL';
  elsif (l_lang = 'SPANISH' or l_lang = 'E') then
    nls_lang := 'SPANISH';
    nls_abb  := 'E';
  elsif (l_lang = 'SWEDISH' or l_lang = 'S') then
    nls_lang := 'SWEDISH';
    nls_abb  := 'S';
  elsif (l_lang = 'THAI' or l_lang = 'TH') then
    nls_lang := 'THAI';
    nls_abb  := 'TH';
  elsif (l_lang = 'TRADITIONAL CHINESE' or l_lang = 'ZHT') then
    nls_lang := 'TRADITIONAL CHINESE';
    nls_abb  := 'ZHT';
  elsif (l_lang = 'TURKISH' or l_lang = 'TR') then
    nls_lang := 'TURKISH';
    nls_abb  := 'TR';
  elsif (l_lang = 'UKRANIAN' or l_lang = 'UK') then
    nls_lang := 'UKRANIAN';
    nls_abb  := 'UK';
  elsif (l_lang = 'VIETNAMESE' or l_lang = 'VN') then
    nls_lang := 'VIETNAMESE';
    nls_abb  := 'VT';
  else
    nls_lang := null;
    nls_abb  := null;
    valid    := false;
  end if;

  return valid;

end check_language;

/*--------------------------- lang_to_abbr -----------------------------*/

FUNCTION lang_to_abbr (
  lang     in  varchar2
) return varchar2
is
  nls_abb varchar2(5) := null;
begin
  if (lang = 'ALL') then
    nls_abb := null;
  elsif (lang = 'AMERICAN') then
    nls_abb  := 'US';
  elsif (lang = 'ARABIC') then
    nls_abb  := 'AR';
  elsif (lang = 'BENGALI') then
    nls_abb  := 'BN';
  elsif (lang = 'BRAZILIAN PORTUGUESE') then
    nls_abb  := 'PTB';
  elsif (lang = 'BULGARIAN') then
    nls_abb  := 'BG';
  elsif (lang = 'CANADIAN FRENCH') then
    nls_abb  := 'FRC';
  elsif (lang = 'CATALAN') then
    nls_abb  := 'CA';
  elsif (lang = 'CROATIAN') then
    nls_abb  := 'HR';
  elsif (lang = 'CZECH') then
    nls_abb  := 'CS';
  elsif (lang = 'DANISH') then
    nls_abb  := 'DK';
  elsif (lang = 'DUTCH') then
    nls_abb  := 'NL';
  elsif (lang = 'EGYPTIAN') then
    nls_abb  := 'EG';
  elsif (lang = 'ENGLISH') then
    nls_abb  := 'GB';
  elsif (lang = 'ESTONIAN') then
    nls_abb  := 'ET';
  elsif (lang = 'FINNISH') then
    nls_abb  := 'SF';
  elsif (lang = 'FRENCH') then
    nls_abb  := 'F';
  elsif (lang = 'GERMAN DIN') then
    nls_abb  := 'DIN';
  elsif (lang = 'GERMAN') then
    nls_abb  := 'D';
  elsif (lang = 'GREEK') then
    nls_abb  := 'EL';
  elsif (lang = 'HEBREW') then
    nls_abb  := 'IW';
  elsif (lang = 'HUNGARIAN') then
    nls_abb  := 'HU';
  elsif (lang = 'ICELANDIC') then
    nls_abb  := 'IS';
  elsif (lang = 'INDONESIAN') then
    nls_abb  := 'IN';
  elsif (lang = 'ITALIAN') then
    nls_abb  := 'I';
  elsif (lang = 'JAPANESE') then
    nls_abb  := 'JA';
  elsif (lang = 'KOREAN') then
    nls_abb  := 'KO';
  elsif (lang = 'LATIN AMERICAN SPANISH') then
    nls_abb  := 'ESA';
  elsif (lang = 'LATVIAN') then
    nls_abb  := 'LV';
  elsif (lang = 'LITHUANIAN') then
    nls_abb  := 'LT';
  elsif (lang = 'MALAY') then
    nls_abb  := 'MS';
  elsif (lang = 'MEXICAN SPANISH') then
    nls_abb  := 'ESM';
  elsif (lang = 'NORWEGIAN') then
    nls_abb  := 'N';
  elsif (lang = 'POLISH' ) then
    nls_abb  := 'PL';
  elsif (lang = 'PORTUGUESE') then
    nls_abb  := 'PT';
  elsif (lang = 'ROMANIAN') then
    nls_abb  := 'RO';
  elsif (lang = 'RUSSIAN') then
    nls_abb  := 'RU';
  elsif (lang = 'SIMPLIFIED CHINESE') then
    nls_abb  := 'ZHS';
  elsif (lang = 'SLOVAK') then
    nls_abb  := 'SK';
  elsif (lang = 'SLOVENIAN') then
    nls_abb  := 'SL';
  elsif (lang = 'SPANISH') then
    nls_abb  := 'E';
  elsif (lang = 'SWEDISH') then
    nls_abb  := 'S';
  elsif (lang = 'THAI') then
    nls_abb  := 'TH';
  elsif (lang = 'TRADITIONAL CHINESE') then
    nls_abb  := 'ZHT';
  elsif (lang = 'TURKISH') then
    nls_abb  := 'TR';
  elsif (lang = 'UKRANIAN') then
    nls_abb  := 'UK';
  elsif (lang = 'VIETNAMESE') then
    nls_abb  := 'VT';
  end if;

  return nls_abb;

end lang_to_abbr;


end driutl;
/

show errors
