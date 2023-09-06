-- CTXDIAG package
-- This package is for analyzing problems with the Oracle Text index $K and $R tables
--
-- The package should be installed as the CTXSYS user then called by the index owner
-- To install as CTXSYS, you should run these commands in SQL*Plus:

--  connect / as sysba   (or SYS/password as sysdba)
--  alter session set current_schema=ctxsys
--  @ctxdiag

-- The various procedures are called with table names, such as the $R table name
-- In generally, this will be
--    DR$<indename>$R for unpartitioned indexes, and
--    DR#<indexname><partitionnumber>$R for a partitioned index
-- However, these names may be different for long index names, or very large numbers of partitions.
-- The user should check carefully the names of tables in the current schema before proceeding.

-- The following drops are expected to give errors if the package has not been previously installed:

drop public synonym ctx_diag;
drop package ctx_diag;
drop type KTableType;
drop type KObjectType;

-- any errors after this point are NOT expected

-- $K row in string format (original $K row uses ROWID type)
create type KObjectType
as object (
  docid    number,
  textkey  varchar2(18))
/
grant execute on KObjectType to public;

-- $K table
create type KTableType
as table of KObjectType
/
grant execute on KTableType to public;

-- CTX DIAGnostics
create package ctx_diag authid current_user as

  -- decode $R in $K format
  function decode_r(
    p_rtab  varchar2)                                          -- $R table name
  return KTableType pipelined;

  -- rebuild $R from $K
  procedure k_to_r(
    p_ktab  varchar2,
    p_rtab  varchar2);

  procedure clear_r(
    p_rtab  varchar2,
    p_docid number);

end ctx_diag;
/
show errors

-- CTX DIAGnostics
create package body ctx_diag as

  type krec_typ is record(                                       -- $K row type
    docid   number,
    textkey rowid);

  type ktab_typ is table of krec_typ index by pls_integer;           -- $K rows

  c_version varchar2(64) := 'August 20, 2018';

  c_from    varchar2(64) :=                               -- base64 from string
            'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
  c_to      varchar2(64);                                   -- base64 to string

  -- decode $R rowid (14 bytes base64 encoded) into string format
  function decode_rowid(
    p_hex  varchar2)
  return varchar2
  is
    v_str     varchar2(18);               -- uncompressed base64 encoded STRing
    v_rowid   varchar2(18);                -- final ROWID after base64 decoding
  begin
    for i in 0..3 loop
      -- char 1, 5, 9, 13
      v_str := v_str || 
        chr(trunc(to_number(substr(p_hex, 6*i + 1, 2), 'XX') / 4));

      -- char 2, 6, 10, 14
      v_str := v_str || 
        chr(  mod(to_number(substr(p_hex, 6*i + 1, 2), 'XX') * 16, 64) +
            trunc(to_number(substr(p_hex, 6*i + 3, 2), 'XX') / 16));

      -- char 3, 7, 11, 15
      v_str := v_str || 
        chr(  mod(to_number(substr(p_hex, 6*i + 3, 2), 'XX') * 4, 64) +
            trunc(to_number(substr(p_hex, 6*i + 5, 2), 'XX') / 64));

      -- char 4, 8, 12, 16
      v_str := v_str || 
        chr(  mod(to_number(substr(p_hex, 6*i + 5, 2), 'XX'), 64));
    end loop;

    -- base64 decode each byte
    v_rowid := translate(v_str, c_to, c_from);

    -- char 17
    v_rowid := v_rowid || chr(to_number(substr(p_hex, 25, 2), 'XX'));

    -- char 18
    v_rowid := v_rowid || chr(to_number(substr(p_hex, 27, 2), 'XX'));

    return v_rowid;
  end decode_rowid;

  -- decode $R in $K format
  function decode_r(
    p_rtab      varchar2)                                      -- $R table name
  return KTableType pipelined
  is
    v_cur       sys_refcursor;                                     -- $R cursor
    v_row       integer;                                   -- current $R row_no
    v_loc       blob;                                         -- $R data column
    v_len       integer;                                         -- BLOB LENgth
    v_buf       raw(14);                          -- $R compressed rowid BUFfer
    v_hex       varchar2(28);                        -- rowid buffer HEX string
    v_doc       integer := 1;                                          -- DOCid
    v_off       integer;                                         -- BLOB OFFset
    v_size      integer := 14;                                 -- $R rowid SIZE
  begin
    open v_cur for 'select row_no, data from '||p_rtab||' order by 1 asc';
    loop
      fetch v_cur into v_row, v_loc;
      exit when v_cur%notfound;

      v_off := 1;
      v_len := dbms_lob.getlength(v_loc);
      while v_off < v_len loop
        dbms_lob.read(v_loc, v_size, v_off, v_buf);
        v_hex := rawtohex(v_buf);

        if v_hex != '0000000000000000000000000000' then         -- skip deleted
          pipe row (KObjectType(v_doc, decode_rowid(v_hex)));
        end if;

        v_doc := v_doc + 1;
        v_off := v_off + 14;
      end loop;
    end loop;
    close v_cur;

    return;
  exception
    when others then
      if v_cur%isopen then
        close v_cur;
      end if;
      raise;
  end decode_r;

  -- write a ROWID to a given BLOB at a given offet
  --   If the offset is beyond the end of the data currently in the LOB,
  --   then zero-byte fillers are inserted in the BLOB. This fact is used
  --   to fill deleted DocIDs that are not present in $K.
  procedure write_rowid(
    r_loc    in out nocopy blob,
    p_pos    integer,
    p_rowid  varchar2)
  is
    v_pos    integer := p_pos;                                  -- local offset
    v_enc    varchar2(18);                       -- base64 encoded ROWID string
    v_int    binary_integer;
    v_buf    raw(8);
  begin
    -- base64 encode each byte
    v_enc := translate(p_rowid, c_from, c_to);

    -- for bytes 1-16 compress each 4 bytes into 3
    --   Each byte is mapped to a 4 byte binary_integer where only the lowest
    --   byte is not zero. When casting to RAW we use little-endian encoding
    --   to map the lowest byte at the lowest offset (value 2 for the second
    --   argument of cast_from_binary_integer).
    for i in 1..4 loop
      -- byte 1
      v_int :=   mod(ascii(substr(v_enc, 1, 1)) *  4, 256) +
               trunc(ascii(substr(v_enc, 2, 1)) / 16);
      v_buf := utl_raw.cast_from_binary_integer(v_int, 2);
      dbms_lob.write(r_loc, 1, v_pos, v_buf);
      v_pos := v_pos + 1;

      -- byte 2
      v_int :=   mod(ascii(substr(v_enc, 2, 1)) * 16, 256) +
               trunc(ascii(substr(v_enc, 3, 1)) /  4);
      v_buf := utl_raw.cast_from_binary_integer(v_int, 2);
      dbms_lob.write(r_loc, 1, v_pos, v_buf);
      v_pos := v_pos + 1;

      -- byte 3
      v_int := mod(ascii(substr(v_enc, 3, 1)) * 64, 256) +
                   ascii(substr(v_enc, 4, 1));
      v_buf := utl_raw.cast_from_binary_integer(v_int, 2);
      dbms_lob.write(r_loc, 1, v_pos, v_buf);
      v_pos := v_pos + 1;

      v_enc := substr(v_enc, 5);
    end loop;

    -- keep byte 17 as is
    v_int := ascii(substr(p_rowid, 17, 1));
    v_buf := utl_raw.cast_from_binary_integer(v_int, 2);
    dbms_lob.write(r_loc, 1, v_pos, v_buf);
    v_pos := v_pos + 1;

    -- keep byte 18 as is
    v_int := ascii(substr(p_rowid, 18, 1));
    v_buf := utl_raw.cast_from_binary_integer(v_int, 2);
    dbms_lob.write(r_loc, 1, v_pos, v_buf);
    v_pos := v_pos + 1;
  end write_rowid;

  -- fill up $R row
  --   Fill up current $R row with zeros to the maximum possible size.
  procedure fill_row(
    r_loc      in out blob,
    c_max_off  integer)
  is
  begin
    -- write a string that maps to all zeros into the last rowid
    write_rowid(r_loc, c_max_off, 'AAAAAAAAAAAAAAAA'||chr(0)||chr(0));
  end fill_row;

  -- read from $K and write into $R
  procedure k_to_r(
    p_ktab  varchar2,
    p_rtab  varchar2)
  is
    c_max       integer;                 -- maximum number of DocIDs per $R row
    c_max_off   integer;                                      -- maximum offset
    v_cnt       integer;                                        -- $R row CouNT
    v_len       integer;                                  -- $R max data LENgth

    v_tab       ktab_typ;                                             -- $K row
    v_cur       sys_refcursor;                                     -- $K cursor
    v_prev      integer := -1;                            -- previous $R row_no
    v_row       integer;                                   -- current $R row_no
    v_off       integer;                             -- offset into data column
    v_loc       blob;                                         -- $R data column
  begin
    -- calibrate $R
    execute immediate
      'select count(*), max(length(data)) from '||p_rtab
       into v_cnt, v_len;
    if v_cnt <= 1 then         -- empty $R is treated as regualar format (200M)
      c_max := 200000000;
    else                                    -- small $R row format (35K or 70K)
      c_max := v_len / 14;
    end if;
    c_max_off := 14*(c_max - 1) + 1;
    v_off := c_max_off;

    -- truncate $R
    execute immediate
      'truncate table '||p_rtab;

    -- read $K
    open v_cur for 'select docid, textkey from '||p_ktab||' order by 1 asc';
    loop
      fetch v_cur bulk collect into v_tab limit 1000;

      -- process the batch
      for i in 1..v_tab.count loop
        v_row := trunc((v_tab(i).docid - 1) / c_max);

        -- init lob locator
        while v_row > v_prev loop
          if v_off < c_max_off then
            fill_row(v_loc, c_max_off);         -- fill previous row with zeros
          end if;
          commit;
          v_off  := 1;
          v_prev := v_prev + 1;

          execute immediate 
            'insert into '||p_rtab||' (row_no, data) '||
            'values (:1, empty_blob())'
          using v_prev;

          execute immediate 
            'select data '||
            'from  '||p_rtab||' '||
            'where  row_no = :1 '||
            'for update'
          into v_loc using v_prev;
        end loop;

        -- write rowid
        v_off := mod(v_tab(i).docid - 1, c_max) * 14 + 1;
        write_rowid(v_loc, v_off, v_tab(i).textkey);
      end loop;

      -- flush the batch
      commit;

      -- we are done
      exit when v_cur%notfound;

      -- restart for the next batch
      execute immediate 
        'select data '||
        'from  '||p_rtab||' '||
        'where  row_no = :1 '||
        'for update'
      into v_loc using v_prev;
    end loop;
    close v_cur;
  exception
    when others then
      if v_cur%isopen then
        close v_cur;
      end if;
      raise;
  end k_to_r;

  procedure clear_r(
    p_rtab  varchar2,
    p_docid number)
  is
    c_max       integer;                 -- maximum number of DocIDs per $R row
    c_max_off   integer;                                      -- maximum offset
    v_cnt       integer;                                        -- $R row CouNT
    v_len       integer;                                  -- $R max data LENgth

    v_tab       ktab_typ;                                             -- $K row
    v_cur       sys_refcursor;                                     -- $K cursor
    v_prev      integer := -1;                            -- previous $R row_no
    v_row       integer;                                   -- current $R row_no
    v_off       integer;                             -- offset into data column
    v_loc       blob;                                         -- $R data column
  begin
    -- calibrate $R
    execute immediate
      'select count(*), max(length(data)) from '||p_rtab
       into v_cnt, v_len;
    if v_cnt <= 1 then         -- empty $R is treated as regualar format (200M)
      c_max := 200000000;
    else                                    -- small $R row format (35K or 70K)
      c_max := v_len / 14;
    end if;

    -- find row and offset
    v_row := trunc((p_docid - 1) / c_max);
    v_off := mod(p_docid - 1, c_max) * 14 + 1;

    -- init lob locator
    execute immediate 
      'select data '||
      'from  '||p_rtab||' '||
      'where  row_no = :1 '||
      'for update'
    into v_loc using v_row;

    -- write a string that maps to all zeros
    write_rowid(v_loc, v_off, 'AAAAAAAAAAAAAAAA'||chr(0)||chr(0));
  end clear_r;

begin
  -- base64 codes
  for i in 0..63 loop
    c_to := c_to || chr(i);
  end loop;
end ctx_diag;
/
show errors

grant execute on ctx_diag to public;
create public synonym ctx_diag for ctx_diag;
