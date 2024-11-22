create or replace procedure showspace (tabname_in varchar2)
as
    ssk number; ssb number; usk number; usb number;
    exk number; exb number; unk number; unb number;
    ufk number; ufb number; f1k number; f1b number;
    f2k number; f2b number; f3k number; f3b number;
    f4k number; f4b number; fuk number; fub number;
begin
    for rws in (select * from user_segments
                where
                (segment_type = 'LOBSEGMENT' or segment_type = 'LOB PARTITION')
                and segment_name in (select segment_name from user_lobs
                                     where
                                           table_name = tabname_in)
                order by segment_name, partition_name)
    loop
        if rws.segment_subtype = 'SECUREFILE' then
          dbms_output.put_line('securefile:' ||
                               ' ' || rws.segment_name ||
                               ' ' || rws.segment_type);
          dbms_space.space_usage(USER,
            rws.segment_name,
            case when rws.segment_type = 'LOBSEGMENT'
              then 'LOB' else 'LOB PARTITION' end,
            ssk, ssb, usk, usb, exk, exb, unk, unb,
            case when rws.segment_type = 'LOBSEGMENT'
              then NULL else rws.partition_name end);
          dbms_output.put_line('seg blocks=' || ssk || ' used=' || usk ||
                               ' expired=' || exk || ' unexpired=' || unk);
        else
          dbms_output.put_line('basicfile:' ||
                               ' ' || rws.segment_name ||
                               ' ' || rws.segment_type);
          dbms_space.space_usage(USER,
            rws.segment_name,
            case when rws.segment_type = 'LOBSEGMENT'
              then 'LOB' else 'LOB PARTITION' end,
            ufk, ufb, f1k, f1b, f2k, f2b, f3k, f3b, f4k, f4b, fuk, fub,
            case when rws.segment_type = 'LOBSEGMENT'
then NULL else rws.partition_name end);
          dbms_output.put_line('unformatted=' || ufk || ' 25%=' || f1k ||
                               ' 50%=' || f2k || ' 75%=' || f3k ||
                               ' <100%=' || f4k || ' full=' || fuk);
        end if;
    end loop;
end;
/
