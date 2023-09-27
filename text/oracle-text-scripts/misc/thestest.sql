set echo on
select count(*) from dr$ths;
select count(*) from dr$ths_bt;
select count(*) from dr$ths_fphrase;
select count(*) from dr$ths_phrase;

begin
  ctx_thes.create_thesaurus('mythes');
end;
/

select count(*) from dr$ths;
select count(*) from dr$ths_bt;
select count(*) from dr$ths_fphrase;
select count(*) from dr$ths_phrase;

begin
  ctx_thes.create_relation('mythes', 'a', 'BT', 'abt');
end;
/

select count(*) from dr$ths_bt;
select count(*) from dr$ths_fphrase;
select count(*) from dr$ths_phrase;
