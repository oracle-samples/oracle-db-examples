set serveroutput off
select /* HELLO */ /*+ INDEX(bob bob_idx) */ num from bob where id = 100;

@plana

