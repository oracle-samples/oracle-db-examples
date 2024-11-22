drop table json_test;

create table json_test (descriptors varchar2(2000));

insert into json_test values ('
{ "Phone": [{"type": "Office","number": "823-555-9969"},
            {"type": "Cell","number": "976-555-1234"}]
}
');

select p.descriptors.PONumber from json_test p
where json_exists(p.descriptors,'$?($.Phone.type == "Office"  && $.Phone.number=="976-555-1234")');

 
