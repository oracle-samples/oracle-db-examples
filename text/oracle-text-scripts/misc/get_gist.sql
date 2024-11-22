
create or replace procedure get_gist (p_id in varchar2) is
   v_query        varchar2(2000);
   v_result       clob;
   v_read_amount  numeric;
   v_read_offset  numeric;
   v_buffer       varchar2(32767);
 begin
   ctx_doc.gist (index_name    => 'med_idx',
                 textkey       => p_id,
                 restab        => v_result,
                 glevel        => 'P',
                 pov           => 'GENERIC',
                 numParagraphs => 4);
   dbms_output.put_line('<html>');
   dbms_output.put_line('<body bgcolor="#ffffff">');
   htp.p('<p>');
   htp.p('<H2>Gist</H2>');
   htp.p('<p><STRONG>');
   v_read_amount := 250;
   v_read_offset := 1;
   begin
     loop
        dbms_lob.read(v_result,v_read_amount,v_read_offset,v_buffer);
        v_buffer := replace (v_buffer, CHR(10)||CHR(10), '<P>'||CHR(10));
        htp.p(v_buffer);
        v_read_offset := v_read_offset + v_read_amount;
        v_read_amount := 32767;
      end loop;
   exception
     when no_data_found then
       null;
       htp.p('</STRONG></body></html>');
   end;
 end get_gist;
/






