drop table bike_items_p2;

create table bike_items_p2 (id number primary key,
  price number,
  descrip varchar2(40),
  dummy varchar2(1)          -- for the UDS
)
;

begin
  for i in 0..99999 loop
    insert into bike_items_p2 values (1+(i*12), 2.50,  'inner tube for MTB wheel', 'X');
    insert into bike_items_p2 values (2+(i*12), 29,    'wheel, front, basic', 'X');
    insert into bike_items_p2 values (3+(i*12), 75,    'wheel, front, top quality', 'X');
    insert into bike_items_p2 values (4+(i*12), 1.99,  'valve caps, set of 4', 'X');
    insert into bike_items_p2 values (5+(i*12), 15.99, 'seat', 'X');
    insert into bike_items_p2 values (6+(i*12), 130,   'hydraulic disk brake, front wheel', 'X');
    insert into bike_items_p2 values (7+(i*12), 25,    'v-type brake, rear wheel', 'X');
    insert into bike_items_p2 values (8+(i*12), 750,   'full-suspension mountain bike', 'X');
    insert into bike_items_p2 values (9+(i*12), 250,   'mountain bike frame', 'X');
    insert into bike_items_p2 values (10+(i*12), 40,   'tires - pair', 'X');
    insert into bike_items_p2 values (11+(i*12), 45,   'wheel, rear, basic', 'X');
    insert into bike_items_p2 values (12+(i*12), 89.99,'wheel, rear top quality', 'X');
  end loop;
end;
/

commit;

