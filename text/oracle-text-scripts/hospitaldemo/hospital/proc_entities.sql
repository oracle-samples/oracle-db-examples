-- CHANGE THIS:

-- create or replace directory HTDOCS as '/usr/local/apache2/htdocs';
create or replace directory HTDOCS as 'C:\Program Files (x86)\Apache Group\Apache2\htdocs';

-- set serverout on

create or replace package entdemo as

-- CHANGE THIS:

  hostname varchar2(80) := 'localhost';

  procedure clob_markup
  (  text    in out nocopy clob,
     offset  number,
     len     number,
     type    varchar2,
     source  varchar2,
     overlap boolean );
  function proc_entities( doc clob ) return clob;
  function write_clob( header varchar2, body clob, footer varchar2, filename varchar2, original_text clob ) return varchar2;
  function write_the_clob( body clob, filename varchar2,original_text clob) return varchar2;

end entdemo;
/
show err

create or replace package body entdemo as

prev_intro  varchar2(2000) := '';
prev_type   varchar2(2000) := '';
prev_source varchar2(2000) := '';
prev_offset number := 0;

procedure clob_markup 
  (  text    in out nocopy clob,
     offset  number,
     len     number,
     type    varchar2,
     source  varchar2,
     overlap boolean ) is

  t clob;
  intro    varchar2(2000);
  dispType varchar2(20);
  class    varchar2(20);
begin

  if source = 'UserRule' or source = 'UserDictionary' then
    dispType := substr(type,2);
    class := 'userhotspot';
  else 
    dispType := type;
    class := 'hotspot';
  end if;

  if overlap then
    intro := '<b><span class="'||class||'">[' || dispType || ', ' || prev_type || ']</span></b>';
  else
    intro := '<b><span class="'||class||'">[' || dispType || ']</span></b>';
  end if;

  --intro := '<'||source||'>';

  dbms_lob.createtemporary( t, true );

  if offset > 0 then
    dbms_lob.copy   ( t, text, offset, 1, 1 );
  end if;

  if overlap then
    dbms_output.put_line( 't'||t );
    dbms_output.put_line( 'x'||text );

    dbms_lob.append ( t, intro );
    dbms_output.put_line( 't'||t );

    dbms_output.put_line  ('-0        1         2         3         4         5         6');
    dbms_output.put_line  ('-1234567890123456789012345678901234567890123456789012345678901234567890');
    dbms_output.put_line( 'length: ' ||to_char(length(text) - prev_offset -length(prev_intro)) || 
                          ' dest_offset: '||to_char(dbms_lob.getlength(t)+1) || 
                          ' src_offset: '|| to_char(prev_offset +length(prev_intro)+1));

    dbms_lob.copy   ( t, text, 
                      length(text) - prev_offset - length(prev_intro),
                      dbms_lob.getlength(t)+1,
                      prev_offset + length(prev_intro)+1);
    dbms_output.put_line('.');
    dbms_output.put_line('t'||t);

    dbms_output.put_line(dbms_lob.getlength(t));
--    dbms_lob.copy   ( text, t, dbms_lob.getlength(t), 1, 1);

    text := t;
    dbms_output.put_line( 'x'||text );

  else 
    dbms_lob.append ( t, intro );
    dbms_lob.copy   ( t, text, dbms_lob.getlength(text) - len, dbms_lob.getlength(t) + 1, offset + len + 1); 
    dbms_lob.copy   ( text, t, dbms_lob.getlength(t), 1 );
  end if;

  -- save the intro because we'll need it next time if there's an overlap
  prev_offset := offset;
  prev_intro  := intro;
  prev_type   := dispType;
  prev_source := source;

end;

function proc_entities( doc clob ) return clob as
  outclob clob;
  last_offset number := -1;   -- don't markup same term twice
  last_length number := 0;    -- needed for overlaps
begin

  dbms_lob.createtemporary(outclob, true);
  dbms_lob.append(outclob, doc);

  for c in (
    select foo.offset, foo.length, foo.type, foo.text, foo.source
    from entities e,
    xmltable( '/entities/entity'
    PASSING e.ENTS
      COLUMNS 
        offset number       PATH '@offset',
        length number       PATH '@length',
        text   varchar2(50) PATH 'text/text()',
        type   varchar2(50) PATH 'type/text()',
        source varchar2(50) PATH '@source' 
    ) as foo order by offset desc ) loop
  
    if (c.offset + c.length > last_offset and last_offset != -1) or (c.offset = last_offset) then
       -- overlap occurs
       clob_markup(outclob, c.offset, c.length, c.type, c.source , true);

    else
       -- no overlap
       clob_markup(outclob, c.offset, c.length, c.type, c.source , false);

    end if;

    last_offset := c.offset;
    last_length := c.length;

  end loop;
  return outclob;

end;

function write_clob( header varchar2, body clob, footer varchar2, filename varchar2, original_text clob ) return varchar2 is

  f        utl_file.file_type;
  vstart   number := 1;
  my_vr    varchar2( 2000 );
  len      number;
  writelen number := 32000;
  x        number;

begin

  f := utl_file.fopen('HTDOCS', filename, 'w', 32767);

  utl_file.put( f, header );

  utl_file.put( f, original_text );

  utl_file.put( f, '<p><h2>Redacted</h2>');

  len := dbms_lob.getlength( body );

  if len < 32000 then

    utl_file.put( f, body );
    utl_file.fflush( f );

  else

    vstart := 1;

    while vstart < len and writelen > 0
    loop
  
      dbms_lob.read( body, writelen, vstart, my_vr );
      utl_file.put( f, my_vr );

      vstart := vstart + writelen;

      x := x - writelen;

      if x < 32000 then
        writelen := x;
      end if;

    end loop;
  end if;

  utl_file.put( f, footer );

  utl_file.fflush( f );
  utl_file.fclose( f );

  return 'http://' || hostname || '/'  || filename;

end;

function write_the_clob( body clob, filename varchar2, original_text clob  )return varchar2 is

  header varchar2(2000) := '
<html>
<head>
 <title>Entity Extraction Demo</title>
 <link rel="stylesheet" type="text/css" href="tooltip/style.css" />
</head>
<body>
<center><table width="70%"><tr><td>
<p />
<h1>Entity Extraction Demo</h1>
<p id=text/>
';

  footer varchar2(2000) := '
</td></tr></table>
<script type="text/javascript" language="javascript" src="tooltip/script.js"></script>
</body>
</html>
';
begin

  return write_clob( header, body, footer, filename, original_text);

end;

end entdemo;
/

-- list 
-- show err
