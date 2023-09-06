set serverout on

-- SQL provides a "bitand" function but not a "bitor"

create or replace function bitor( x integer, y integer ) return integer is
begin
  return ( x + y - bitand(x, y) );
end;
/

-- turn a binary string with arbitrary spaces dots and x's into number
-- dots and spaces are spacing, x's represent 0's

create or replace function binstr2num( binNumber varchar2 ) return integer is 
  binStr varchar2(256);
  theNum integer := 0;
  bitPos integer := 0; -- bit position from left
begin
  
  binStr := replace(binNumber, '.');
  binStr := replace(binStr, ' ');
  binStr := replace(binStr, 'x', '0');

  for i in 1 .. length(binStr) loop
    
    bitPos := length(binStr) - i;
    if substr(binStr, length(binStr) - i + 1, 1 ) = '1' then
        theNum := theNum + (2** (i -1));  
    end if;
  end loop;

  return theNum;

end;
/
show err

-- return a binary numnber as a string representation
-- eg num2binstr (9) would return '1001'

create or replace function num2binstr( num integer ) return varchar2 is
  outStr varchar2(64) := '';
  maxbits integer;
  numRemain integer := num;
begin
  for i in 1 .. 64 loop
    if 2**(i-1) > num then 
       maxbits := i - 1;
       exit;
    end if;
  end loop;

  for i in 1 .. maxbits loop

    if numRemain / 2**(maxbits - i) >= 1 then
      outStr := outStr || '1';
      numRemain := numRemain - 2**(maxbits - 1);
    else 
      outStr := outStr || '0';
    end if;

  end loop;
  
  return outStr;
end;
/
show err

-- is a particular bit set in a number?

create or replace function isBitSet( num integer, bitPos integer ) return boolean is
  r integer;
begin
  if bitAnd( num, (2**(bitPos-1)) ) > 0 then
    return true;
  end if;
  return false;
end;
/
list
show err

-- set a bit in a number

create or replace function setBit( num integer, bitPos integer ) return integer is
begin
  return bitOr( num, (2**(bitPos-1)) );
end;
/
show err

-- create a 2 to 4 byte UTF8 character from a Unicode codepoint
-- the 'x' characters in the mask string are replaced by bits from
-- the Unicode codepoint

create or replace function makeutf8( codepoint integer, bytes integer ) return number is
  maskStr      varchar2(256);
  maskStrNoSpc varchar2(256);
  outNum       integer;
  maskBitPos   integer;
  cpBitPos     integer := 0;

begin

  if bytes = 1 then
    maskStr := '0xxx.xxxx';
  end if;
  if bytes = 2 then
    maskStr := '110x.xxxx 10xx.xxxx';
  end if;
  if bytes = 3 then
    maskStr := '1110.xxxx 10xx.xxxx 10xx.xxxx';
  end if;
  if bytes = 4 then
    maskStr := '1111.0xxx 10xx.xxxx 10xx.xxxx 10xx.xxxx';
  end if;

  maskStrNoSpc := replace( replace(maskStr, ' ', ''), '.', '');

  outNum := binstr2num( maskStr );

  for i in 1 .. length(maskStrNoSpc) loop
    if substr(maskStrNoSpc, length(maskStrNoSpc)-i+1, 1) = 'x' then
      maskBitPos := length(maskStrNoSpc)+1 - ( length(maskStrNoSpc)-i+1 );
      cpBitPos   := cpBitPos + 1;

      if ( isBitSet( codePoint, cpBitPos ) ) then
         outNum := setBit( outNum, maskBitPos );
      end if;

    end if;
  end loop;
  
  return outnum;
end;
/
show err


drop table test_table_1byte;
drop table test_table_2byte;
drop table test_table_3byte;
drop table test_table_4byte;

create table test_table_1byte( codepoint varchar2(4), utf8string varchar2(6), text varchar2(50) );
create table test_table_2byte( codepoint varchar2(4), utf8string varchar2(6), text varchar2(50) );
create table test_table_3byte( codepoint varchar2(4), utf8string varchar2(6), text varchar2(50) );
create table test_table_4byte( codepoint varchar2(6), utf8string varchar2(8), text varchar2(50) );

set timing on

-- The range of characters encoded with 1 bytes in UTF-8 is ... U+0000 - U+007F
-- The range of characters encoded with 2 bytes in UTF-8 is ... U+0080 - U+07FF
-- The range of characters encoded with 3 bytes in UTF-8 is ... U+0800-U+D800 and U+E000-U+FFFF
-- The range of characters encoded with 4 bytes in UTF-8 is ... U+010000 - U+10FFFF

declare
begin

  -- 1 bytes

  for i in to_number('0000', 'XXXX') .. to_number('007F', 'XXXX') loop
    insert into test_table_1byte values ( trim(to_char( i, 'XXXX' )), trim(to_char(  makeutf8(i, 1), 'XXXXXX' ) ),
                               'U+' || trim(to_char( i, 'XXXX' )) ||
                               ' '|| '0x' ||trim(to_char(  makeutf8(i, 1), 'XXXXXX' ) )
                               || unistr( '\' || lpad( replace(to_char( i, 'XXXX'), ' ', ''), 4, '0' ) ) );
                               
  end loop;

  -- 2 bytes

  for i in to_number('0080', 'XXXX') .. to_number('07FF', 'XXXX') loop
    insert into test_table_2byte values ( trim(to_char( i, 'XXXX' )), trim(to_char(  makeutf8(i, 2), 'XXXXXX' ) ),
                               'U+' || trim(to_char( i, 'XXXX' )) ||
                               ' '|| '0x' ||trim(to_char(  makeutf8(i, 2), 'XXXXXX' ) )
                               || unistr( '\' || lpad( replace(to_char( i, 'XXXX'), ' ', ''), 4, '0' ) ) );
                               
  end loop;

  -- 3 bytes

  for i in to_number('0800', 'XXXX') .. to_number('D800', 'XXXX') loop
    insert into test_table_3byte values ( trim(to_char( i, 'XXXX' )), trim(to_char(  makeutf8(i, 3), 'XXXXXX' ) ),
                               'U+' || trim(to_char( i, 'XXXX' )) ||
                               ' '|| '0x' ||trim(to_char(  makeutf8(i, 3), 'XXXXXX' ) )
                               || unistr( '\' || lpad( replace(to_char( i, 'XXXX'), ' ', ''), 4, '0' ) ) );
                               
  end loop;
  for i in to_number('E000', 'XXXX') .. to_number('FFFF', 'XXXX') loop
    insert into test_table_3byte values ( trim(to_char( i, 'XXXX' )), trim(to_char(  makeutf8(i, 3), 'XXXXXX' )),
                               'U+' || trim(to_char( i, 'XXXX' )) ||
                               ' '|| '0x' ||trim(to_char(  makeutf8(i, 3), 'XXXXXX' ) )
                               || unistr( '\' || lpad( replace(to_char( i, 'XXXX'), ' ', ''), 4, '0' ) ) );
  end loop;

  -- 4 bytes

  for i in to_number('010000', 'XXXXXX') .. to_number('10FFFF', 'XXXXXX') loop
    insert into test_table_4byte values ( trim(to_char( i, 'XXXXXX' )), trim(to_char(  makeutf8(i, 4), 'XXXXXXXX' )),
                               'U+' || trim(to_char( i, 'XXXXXX' )) ||
                               ' '|| '0x' ||trim(to_char(  makeutf8(i, 4), 'XXXXXXXX' ) )
                               || unistr( '\' || lpad( replace(to_char( i, 'XXXXXX'), ' ', ''), 6, '0' ) ) );
  end loop;
end;
/

exec ctx_ddl.drop_preference( 'my_lexer')
exec ctx_ddl.create_preference( 'my_lexer', 'WORLD_LEXER' )

delete from ctx_user_index_errors;

-- Create index on all the 1-byte chars and look for errors

create index test_index_1byte on test_table_1byte (text) indextype is ctxsys.context
parameters ('lexer my_lexer')
/
select err_text, text from ctx_user_index_errors e, test_table_1byte t
where chartorowid( e.err_textkey ) = t.rowid
/
-- just the data
select text from ctx_user_index_errors e, test_table_1byte t
where chartorowid( e.err_textkey ) = t.rowid
/

-- Create index on all the 2-byte chars and look for errors

create index test_index_2byte on test_table_2byte (text) indextype is ctxsys.context
parameters ('lexer my_lexer')
/
select err_text, text from ctx_user_index_errors e, test_table_2byte t
where chartorowid( e.err_textkey ) = t.rowid
/
-- just the data
select text from ctx_user_index_errors e, test_table_2byte t
where chartorowid( e.err_textkey ) = t.rowid
/

-- Create index on all the 3-byte chars and look for errors

create index test_index_3byte on test_table_3byte (text) indextype is ctxsys.context
parameters ('lexer my_lexer')
/
select err_text, text from ctx_user_index_errors e, test_table_3byte t
where chartorowid( e.err_textkey ) = t.rowid
/
-- just the data
select text from ctx_user_index_errors e, test_table_3byte t
where chartorowid( e.err_textkey ) = t.rowid
/

-- Create index on all the 4-byte chars and look for errors

create index test_index_4byte on test_table_4byte (text) indextype is ctxsys.context
parameters ('lexer my_lexer')
/
select err_text, text from ctx_user_index_errors e, test_table_4byte t
where chartorowid( e.err_textkey ) = t.rowid
/
-- just the data
select text from ctx_user_index_errors e, test_table_4byte t
where chartorowid( e.err_textkey ) = t.rowid
/
