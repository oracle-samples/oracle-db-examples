connect ctxsys/ctxsys

create or replace
procedure My_Proc

  (
    rid  in              rowid,
    tlob in out NOCOPY   clob    /* NOCOPY instructs Oracle to pass
                                    this argument as fast as possible */
  )
is
  v_descrip                       varchar2(4000);

  v_buffer                       varchar2(4000);
  v_length                       integer;
begin

  /* the real logic */
  select descrip
    into v_describ
    from roger.bike_samples_p where rowid = rid;

  v_buffer := v_descrip;
  v_length := length ( v_buffer );

  Dbms_Lob.Trim
    (
      lob_loc        => tlob,
      newlen         => 0
    );

  Dbms_Lob.Write
    (
      lob_loc        => tlob,
      amount         => v_length,
      offset         => 1,
      buffer         => v_buffer
    );

end My_Proc;
/
Show Errors

grant execute on My_Proc to public;

