REM   Script: Analytics - How null values are treated
REM   SQL from the KISS (Keep It Simply SQL) Analytic video series by Developer Advocate Connor McDonald. This script is for looking how nulls are treated.

Run this script standalone, or take it as part of the complete Analytics class at https://tinyurl.com/devgym-classes

drop table planets cascade constraints purge;

create table planets ( name varchar2(20) primary key );

insert into planets values ('Mercury');

insert into planets values ('Venus');

insert into planets values ('Earth');

insert into planets values ('Eris');

insert into planets values ('Haumea');

insert into planets values ('Jupiter');

insert into planets values ('Mars');

insert into planets values ('Neptune');

insert into planets values ('Pluto');

insert into planets values ('Saturn');

insert into planets values ('Uranus');

drop table moons purge;

create table moons ( planet_name varchar2(20) references planets ( name ), name varchar2(20) primary key , radius number(12,2) ) ;

insert into moons values ('','',);

insert into moons values ('Earth','Moon',1737.1);

insert into moons values ('Eris','Dysnomia',342);

insert into moons values ('Haumea','Hi?iaka',195);

insert into moons values ('Haumea','Namaka',100);

insert into moons values ('Jupiter','Adrastea',8.2 );

insert into moons values ('Jupiter','Aitne',1.5);

insert into moons values ('Jupiter','Amalthea',83.45 );

insert into moons values ('Jupiter','Ananke',14);

insert into moons values ('Jupiter','Aoede',2);

insert into moons values ('Jupiter','Arche',1.5);

insert into moons values ('Jupiter','Autonoe',2);

insert into moons values ('Jupiter','Callirrhoe',4.3);

insert into moons values ('Jupiter','Callisto',2408.4 );

insert into moons values ('Jupiter','Carme',23);

insert into moons values ('Jupiter','Carpo',1.5);

insert into moons values ('Jupiter','Chaldene',1.9);

insert into moons values ('Jupiter','Cyllene',1);

insert into moons values ('Jupiter','Dia',2);

insert into moons values ('Jupiter','Elara',43);

insert into moons values ('Jupiter','Erinome',1.6);

insert into moons values ('Jupiter','Euanthe',1.5);

insert into moons values ('Jupiter','Eukelade',2);

insert into moons values ('Jupiter','Euporie',1);

insert into moons values ('Jupiter','Europa',1560.7 );

insert into moons values ('Jupiter','Eurydome',1.5);

insert into moons values ('Jupiter','Ganymede',2634.1 );

insert into moons values ('Jupiter','Harpalyke',2.2);

insert into moons values ('Jupiter','Hegemone',1.5);

insert into moons values ('Jupiter','Helike',2);

insert into moons values ('Jupiter','Hermippe',2);

insert into moons values ('Jupiter','Herse',1);

insert into moons values ('Jupiter','Himalia',67 );

insert into moons values ('Jupiter','Io',1818.1 );

insert into moons values ('Jupiter','Iocaste',2.6);

insert into moons values ('Jupiter','Isonoe',1.9);

insert into moons values ('Jupiter','Kale',1);

insert into moons values ('Jupiter','Kallichore',1);

insert into moons values ('Jupiter','Kalyke',2.6);

insert into moons values ('Jupiter','Kore',1);

insert into moons values ('Jupiter','Leda',10);

insert into moons values ('Jupiter','Lysithea',18);

insert into moons values ('Jupiter','Megaclite',2.7);

insert into moons values ('Jupiter','Metis',21.5 );

insert into moons values ('Jupiter','Mneme',1);

insert into moons values ('Jupiter','Orthosie',1);

insert into moons values ('Jupiter','Pasiphae',30);

insert into moons values ('Jupiter','Pasithee',1);

insert into moons values ('Jupiter','Praxidike',3.4);

insert into moons values ('Jupiter','S/2003 J 10',1);

insert into moons values ('Jupiter','S/2003 J 12',0.5);

insert into moons values ('Jupiter','S/2003 J 15',1);

insert into moons values ('Jupiter','S/2003 J 16',1);

insert into moons values ('Jupiter','S/2003 J 18',1);

insert into moons values ('Jupiter','S/2003 J 19',1);

insert into moons values ('Jupiter','S/2003 J 2',1);

insert into moons values ('Jupiter','S/2003 J 23',1);

insert into moons values ('Jupiter','S/2003 J 3',1);

insert into moons values ('Jupiter','S/2003 J 4',1);

insert into moons values ('Jupiter','S/2003 J 5',2);

insert into moons values ('Jupiter','S/2003 J 9',0.5);

insert into moons values ('Jupiter','S/2010 J 1',1);

insert into moons values ('Jupiter','S/2010 J 2',0.5);

insert into moons values ('Jupiter','S/2011 J 1',0.5);

insert into moons values ('Jupiter','S/2011 J 2',0.5);

insert into moons values ('Jupiter','Sinope',19);

insert into moons values ('Jupiter','Sponde',1);

insert into moons values ('Jupiter','Taygete',2.5);

insert into moons values ('Jupiter','Thebe',49.3 );

insert into moons values ('Jupiter','Thelxinoe',1);

insert into moons values ('Jupiter','Themisto',4);

insert into moons values ('Jupiter','Thyone',2);

insert into moons values ('Mars','Deimos',6.2 );

insert into moons values ('Mars','Phobos',11.1 );

insert into moons values ('Neptune','Despina',75 );

insert into moons values ('Neptune','Galatea',88 );

insert into moons values ('Neptune','Halimede',31);

insert into moons values ('Neptune','Laomedeia',21);

insert into moons values ('Neptune','Larissa',97 );

insert into moons values ('Neptune','Naiad',33 );

insert into moons values ('Neptune','Nereid',170 );

insert into moons values ('Neptune','Neso',30);

insert into moons values ('Neptune','Proteus',210 );

insert into moons values ('Neptune','Psamathe',20);

insert into moons values ('Neptune','S/2004 N 1',8);

insert into moons values ('Neptune','Sao',22);

insert into moons values ('Neptune','Thalassa',41 );

insert into moons values ('Neptune','Triton',1353.4 );

insert into moons values ('Pluto','Charon',603.6 );

insert into moons values ('Pluto','Hydra',30.5);

insert into moons values ('Pluto','Kerberos',6.5);

insert into moons values ('Pluto','Nix',23);

insert into moons values ('Pluto','Styx',5);

insert into moons values ('Saturn','Aegaeon',0.25);

insert into moons values ('Saturn','Aegir',3);

insert into moons values ('Saturn','Albiorix',16);

insert into moons values ('Saturn','Anthe',1);

insert into moons values ('Saturn','Atlas',15.3 );

insert into moons values ('Saturn','Bebhionn',3);

insert into moons values ('Saturn','Bergelmir',3);

insert into moons values ('Saturn','Bestla',3.5);

insert into moons values ('Saturn','Calypso',9.5 );

insert into moons values ('Saturn','Daphnis',3);

insert into moons values ('Saturn','Dione',562.5 );

insert into moons values ('Saturn','Enceladus',252.3 );

insert into moons values ('Saturn','Epimetheus',58.3 );

insert into moons values ('Saturn','Erriapus',5);

insert into moons values ('Saturn','Farbauti',2.5);

insert into moons values ('Saturn','Fenrir',2);

insert into moons values ('Saturn','Fornjot',3);

insert into moons values ('Saturn','Greip',3);

insert into moons values ('Saturn','Hati',3);

insert into moons values ('Saturn','Helene',16 );

insert into moons values ('Saturn','Hyperion',133.0 );

insert into moons values ('Saturn','Hyrrokkin',4);

insert into moons values ('Saturn','Iapetus',734.5 );

insert into moons values ('Saturn','Ijiraq',6);

insert into moons values ('Saturn','Janus',90.4 );

insert into moons values ('Saturn','Jarnsaxa',3);

insert into moons values ('Saturn','Kari',3.5);

insert into moons values ('Saturn','Kiviuq',8);

insert into moons values ('Saturn','Loge',3);

insert into moons values ('Saturn','Methone',1.6);

insert into moons values ('Saturn','Mimas',198.2 );

insert into moons values ('Saturn','Mundilfari',3.5);

insert into moons values ('Saturn','Narvi',3.5);

insert into moons values ('Saturn','Paaliaq',11);

insert into moons values ('Saturn','Pallene',2);

insert into moons values ('Saturn','Pan',12.8);

insert into moons values ('Saturn','Pandora',40.6 );

insert into moons values ('Saturn','Phoebe',106.6 );

insert into moons values ('Saturn','Polydeuces',1.25);

insert into moons values ('Saturn','Prometheus',46.8 );

insert into moons values ('Saturn','Rhea',764.5 );

insert into moons values ('Saturn','S/2004 S 12',2.5);

insert into moons values ('Saturn','S/2004 S 13',3);

insert into moons values ('Saturn','S/2004 S 17',2);

insert into moons values ('Saturn','S/2004 S 7',3);

insert into moons values ('Saturn','S/2006 S 1',3);

insert into moons values ('Saturn','S/2006 S 3',3);

insert into moons values ('Saturn','S/2007 S 2',3);

insert into moons values ('Saturn','S/2007 S 3',3);

insert into moons values ('Saturn','S/2009 S 1',0.15);

insert into moons values ('Saturn','Siarnaq',20);

insert into moons values ('Saturn','Skathi',4);

insert into moons values ('Saturn','Skoll',3);

insert into moons values ('Saturn','Surtur',3);

insert into moons values ('Saturn','Suttungr',3.5);

insert into moons values ('Saturn','Tarqeq',3.5);

insert into moons values ('Saturn','Tarvos',7.5);

insert into moons values ('Saturn','Telesto',12 );

insert into moons values ('Saturn','Tethys',536.3 );

insert into moons values ('Saturn','Thrymr',3.5);

insert into moons values ('Saturn','Titan',2575.5 );

insert into moons values ('Saturn','Ymir',9);

insert into moons values ('Uranus','Ariel',578.9 );

insert into moons values ('Uranus','Belinda',40.3 );

insert into moons values ('Uranus','Bianca',25.7 );

insert into moons values ('Uranus','Caliban',49);

insert into moons values ('Uranus','Cordelia',20.1 );

insert into moons values ('Uranus','Cressida',39.8 );

insert into moons values ('Uranus','Cupid',5);

insert into moons values ('Uranus','Desdemona',32.0 );

insert into moons values ('Uranus','Ferdinand',6);

insert into moons values ('Uranus','Francisco',6);

insert into moons values ('Uranus','Juliet',46.8 );

insert into moons values ('Uranus','Mab',5);

insert into moons values ('Uranus','Margaret',5.5);

insert into moons values ('Uranus','Miranda',235.8 );

insert into moons values ('Uranus','Oberon',761.4 );

insert into moons values ('Uranus','Ophelia',21.4 );

insert into moons values ('Uranus','Perdita',10);

insert into moons values ('Uranus','Portia',67.6 );

insert into moons values ('Uranus','Prospero',15);

insert into moons values ('Uranus','Puck',81 );

insert into moons values ('Uranus','Rosalind',36 );

insert into moons values ('Uranus','Setebos',15);

insert into moons values ('Uranus','Stephano',10);

insert into moons values ('Uranus','Sycorax',75);

insert into moons values ('Uranus','Titania',788.9 );

insert into moons values ('Uranus','Trinculo',5);

insert into moons values ('Uranus','Umbriel',584.7 );

commit


select p.name planet, m.name, m.radius,  
       row_number() over ( order by radius desc ) as size_rank 
from planets p, moons m 
where p.name = m.planet_name(+) 
and p.name in ('Mars','Venus','Pluto','Mercury','Neptune') 
order by size_rank;

select p.name planet, m.name, m.radius,  
       row_number() over ( order by radius desc NULLS LAST ) as size_rank 
from planets p, moons m 
where p.name = m.planet_name(+) 
and p.name in ('Mars','Venus','Pluto','Mercury','Neptune');

select p.name planet, m.name, m.radius, 
       rank() over ( order by radius desc ) as size_rank 
from planets p, moons m 
where p.name = m.planet_name(+) 
and p.name in ('Mars','Venus','Pluto','Mercury','Neptune') 
order by size_rank;

