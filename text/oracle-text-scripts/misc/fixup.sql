set define off

create or replace function fixup (instr varchar2) return varchar2 is
  wkspace varchar2(4000);
begin
  wkspace := instr;

  /* Add a leading space */
  wkspace := ' ' || wkspace;

  /* Remove break characters */
  wkspace := translate (wkspace, '"!$^&*+{}[]:@~;#<>?,./', ' ');

  /* Remove any words consisting only of wildcards */
  wkspace := replace (wkspace, ' %% ', ' ');

  /* Remove any leading % signs after a space */
  wkspace := replace (wkspace, ' %', ' ');

  return wkspace;
end;
/

