create or replace directory HTDOCS as '/usr/local/apache2/htdocs/';
/

-- set serverout on

create or replace package entdemo as

  procedure clob_markup
  (  text    in out nocopy clob,
     offset  number,
     len     number,
     type    varchar2,
     source  varchar2,
     overlap boolean );
  function proc_entities( doc clob ) return clob;
  function write_clob( header varchar2, body clob, footer varchar2, filename varchar2 ) return varchar2;
  function write_the_clob( body clob, filename varchar2 )return varchar2;

end entdemo;
/
show err

create or replace package body entdemo as

prev_intro varchar2(2000) := '';

procedure clob_markup 
  (  text    in out nocopy clob,
     offset  number,
     len     number,
     type    varchar2,
     source  varchar2,
     overlap boolean ) is

  t clob;
  intro varchar2(2000);
  outro varchar2(2000);

begin

  intro := '<b><span class="hotspot" onmouseover="tooltip.show(''' || type || ' (' || source || ')'');" onmouseout="tooltip.hide();">';
  outro := '</span></b>';

  --intro := '<'||source||'>';
  --outro := '<x>';

  dbms_lob.createtemporary( t, true );

  if offset > 0 then
    dbms_lob.copy   ( t, text, offset, 1, 1 );
  end if;

  if overlap then
    dbms_output.put_line('overlap is true');
    dbms_output.put_line( '1'||t );
    dbms_lob.append ( t, intro );
    dbms_output.put_line( '2'||t );
    dbms_lob.copy   ( t, text, len + length(prev_intro), offset + length(intro) + 1, offset + 1 );
    dbms_output.put_line( '3'||t );
    dbms_lob.append ( t, outro);
    dbms_output.put_line( 't'||t );

    dbms_output.put_line  ('x'||text);
    dbms_output.put_line  ('-0        1         2         3         4         5         6');
    dbms_output.put_line  ('-123456789012345678901234567890123456789012345678901234567890');
    dbms_output.put_line  ('length: '|| to_char(dbms_lob.getlength(text) - offset - len - length(prev_intro) ) );
    dbms_output.put_line  ('dest offset: '|| to_char( offset + len + length(intro) + length(prev_intro) + length(outro) + 1 ) );
    dbms_output.put_line  ('source offset '|| to_char( offset + len + length(prev_intro) + 1) );
    dbms_lob.copy   ( t, text, 
                      dbms_lob.getlength(text) - offset - len - length(prev_intro), 
                      offset + len + length(intro) + length(prev_intro) + length(outro) + 1, 
                      offset + len + length(prev_intro) + 1); 

    dbms_output.put_line( '5'||t );
    dbms_lob.copy   ( text, t, dbms_lob.getlength(t), 1 );

  else 
    dbms_output.put_line('overlap is false');
    dbms_output.put_line( 'a'||t );
    dbms_lob.append ( t, intro );
    dbms_output.put_line( 'b'||t );
    dbms_lob.copy   ( t, text, len, offset + length(intro) + 1, offset + 1 );
    dbms_output.put_line( 'c'||t );
    dbms_lob.append ( t, outro);
    dbms_output.put_line( 'd'||t );
    dbms_lob.copy   ( t, text, dbms_lob.getlength(text) - len, offset + len + length(intro) + length(outro) + 1, offset + len + 1); 
    dbms_output.put_line( 'e'||t );
    dbms_lob.copy   ( text, t, dbms_lob.getlength(t), 1 );
    dbms_output.put_line( '0'||t );
  end if;

  -- save the intro because we'll need it next time if there's an overlap
  prev_intro := intro;

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
  
    if c.offset != last_offset then

      if c.offset + c.length > last_offset and last_offset != -1 then
         -- overlap occurs
         dbms_output.put_line('overlap is defined true');
         clob_markup(outclob, c.offset, c.length, c.type, c.source , true);

      else
         -- no overlap
         dbms_output.put_line('overlap is defined untrue');
         clob_markup(outclob, c.offset, c.length, c.type, c.source , false);

      end if;
    end if;
    last_offset := c.offset;
    last_length := c.length;

  end loop;
  return outclob;

end;

function write_clob( header varchar2, body clob, footer varchar2, filename varchar2 ) return varchar2 is

  f        utl_file.file_type;
  vstart   number := 1;
  my_vr    varchar2( 2000 );
  len      number;
  writelen number := 32000;
  x        number;

begin

  f := utl_file.fopen('HTDOCS', filename, 'w', 32767);

  utl_file.put( f, header );

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

  return 'http://adc2190498.us.oracle.com/' || filename;

end;

function write_the_clob( body clob, filename varchar2 )return varchar2 is

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

  return write_clob( header, body, footer, filename );

end;

end entdemo;
/
show err


