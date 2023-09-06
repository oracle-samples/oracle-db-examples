begin
  for j in 1..100 loop
    dbms_lob.createtemporary(clb,true);
    for i in 1..20000 loop
      dbms_lob.append(clb, 'foo ');
      end loop;
    insert into foo values (clb);
  end loop;
end
/
