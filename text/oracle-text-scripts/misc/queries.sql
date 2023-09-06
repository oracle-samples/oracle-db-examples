variable bindv varchar2(4000);
column text format a30
set timing on

-- Selective text, unselective date

select count(*) from tab128k 
  where the_date <= '1-FEB-2079';

select to_char(the_date, 'DD-MON-YYYY'), text from tab128k 
  where contains (text, 'row12345') > 0;

select to_char(the_date, 'DD-MON-YYYY'), text from tab128k 
  where the_date <= '1-FEB-2079'
    and contains (text, 'row12345') > 0;

begin
 :bindv := 'row12345 AND ';
 :bindv := :bindv ||
     ctx_cd.date_contains ('t128k', 'the_date', '1-FEB-1992', null, 'L');
end;
/
select to_char(the_date, 'DD-MON-YYYY'), text from tab128k 
  where contains (concat, :bindv) > 0;


-- Unselective text, selective date
select to_char(the_date, 'DD-MON-YYYY'), text from tab128k
  where the_date = '1-OCT-1993';

select count(*) from tab128k
  where contains (text, 'data') > 0;

select to_char(the_date, 'DD-MON-YYYY'), text from tab128k
  where the_date = '1-OCT-1993'
    and contains (text, 'data') > 0;

begin
 :bindv := 'data AND ';
 :bindv := :bindv ||
     ctx_cd.date_contains ('t128k', 'the_date', '1-OCT-1993', null, 'E');
end;
/
print bindv

select to_char(the_date, 'DD-MON-YYYY'), text from tab128k
  where contains (concat, :bindv) > 0;


Unselective text and date

select count(*) from tab128k where the_date >= '18-MAR-1991';
select count(*) from tab128k where contains (text, 'data') > 0;

select count(*) from tab128k where contains (text, 'data') > 0
and the_date > '20-JAN-2079';

variable bindv varchar2(4000);

begin
 :bindv := 'data AND ';
 :bindv := :bindv ||
     ctx_cd.date_contains ('t128k', 'the_date', '20-JAN-1994', null, 'G');
end;
/
print bindv

select count(*) from tab128k where contains (concat, :bindv) > 0; 



set serveroutput on

create or replace procedure runit (query varchar2) is
    v_date        date;
    v_text        varchar2(30);
    type rf_type  is ref cursor;
    rc            rf_type;
begin
    open rc for query;
    loop
        fetch rc into v_date, v_text;
        exit when rc%notfound;
        dbms_output.put_line(to_char(v_date, 'DD-MON-YYYY') || '  ' || v_text);
    end loop;
end;
/
