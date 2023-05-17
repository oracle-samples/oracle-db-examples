REM   Script: Analytics - More complex ranking functions
REM   SQL from the KISS (Keep It Simply SQL) Analytic video series by Developer Advocate Connor McDonald. This script demonstrates the PERCENT_RANK, CUME_DIST and NTILE functions.

Run this script standalone, or take it as part of the complete Analytics class at https://tinyurl.com/devgym-classes

drop table movies purge;

-- Note - the data in this table may be correct, it may be fictional.  It was just harvested from the web so please dont rely on it.
create table movies 
  ( year_of_release number(4),
    name varchar2(60),
    gross_sales number(12)
  );

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2009,'Avatar',2783918982);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (1997,'Titanic',2207615668);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2015,'Jurassic World',1666248032);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2012,'The Avengers',1519479547);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2015,'Furious 7',1515993181);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2015,'The Avengers: Age of Ultron',1404705868);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2011,'Harry Potter and the Deathly Hallows: Part II',1341511219);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2013,'Frozen',1274234980);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2013,'Iron Man 3',1215392272);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2015,'Minions',1163530631);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2003,'The Lord of the Rings: The Return of the King',1141408667);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2011,'Transformers: Dark of the Moon',1123790543);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2012,'Skyfall',1110526981);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2014,'Transformers: Age of Extinction',1104039076);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2012,'The Dark Knight Rises',1084439099);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2010,'Toy Story 3',1069818229);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2006,'Pirates of the Caribbean: Dead Man''s Chest',1066215812);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2011,'Pirates of the Caribbean: On Stranger Tides',1045663875);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (1993,'Jurassic Park',1038812584);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (1999,'Star Wars Ep. I: The Phantom Menace',1027044677);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2010,'Alice in Wonderland',1025491110);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2012,'The Hobbit: An Unexpected Journey',1017003568);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2008,'The Dark Knight',1002891358);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (1994,'The Lion King',987480140);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2013,'Despicable Me 2',974873764);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2001,'Harry Potter and the Sorcerer''s Stone',974755371);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2007,'Pirates of the Caribbean: At World''s End',963420425);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2013,'The Hobbit: The Desolation of Smaug',960366855);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2010,'Harry Potter and the Deathly Hallows: Part I',959301070);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2014,'The Hobbit: The Battle of the Five Armies',955119788);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2007,'Harry Potter and the Order of the Phoenix',942943935);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2003,'Finding Nemo',936429370);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2009,'Harry Potter and the Half-Blood Prince',935083686);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2002,'The Lord of the Rings: The Two Towers',934703179);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2004,'Shrek 2',932252921);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2005,'Harry Potter and the Goblet of Fire',896911078);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2007,'Spider-Man 3',890875303);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2001,'The Lord of the Rings: The Fellowship of the Ring',887217688);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2012,'Ice Age: Continental Drift',879765137);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2002,'Harry Potter and the Chamber of Secrets',878979634);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2013,'The Hunger Games: Catching Fire',864868047);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2009,'Ice Age: Dawn of the Dinosaurs',859701857);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2015,'Inside Out',853031215);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2005,'Star Wars Ep. III: Revenge of the Sith',848998877);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2009,'Transformers: Revenge of the Fallen',836519699);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2010,'Inception',832584416);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2012,'The Twilight Saga: Breaking Dawn, Part 2',829724737);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2015,'Spectre',821980199);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2002,'Spider-Man',821706375);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (1996,'Independence Day',817355682);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2007,'Shrek the Third',805623351);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2004,'Harry Potter and the Prisoner of Azkaban',796688549);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (1982,'ET: The Extra-Terrestrial',792804231);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2013,'Fast and Furious 6',789952811);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2009,'2012',788408539);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2008,'Indiana Jones and the Kingdom of the Crystal Skull',786558145);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (1977,'Star Wars Ep. IV: A New Hope',786535665);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2004,'Spider-Man 2',783705001);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2014,'Guardians of the Galaxy',771172112);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2006,'The Da Vinci Code',767820459);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2014,'Maleficent',758536735);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2012,'The Amazing Spider-Man',757890267);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2010,'Shrek Forever After',755903876);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2014,'X-Men: Days of Future Past',748121534);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2012,'Madagascar 3: Europe''s Most Wanted',746921271);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2013,'Monsters University',743588329);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2003,'The Matrix Reloaded',738576929);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2009,'Up',731542621);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2005,'The Chronicles of Narnia',720539572);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2013,'Gravity',716392705);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2014,'Captain America: The Winter Soldier',713846958);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2014,'The Hunger Games: Mockingjay - Part 1',709635885);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2014,'The Amazing Spider-Man 2',708996336);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2007,'Transformers',708098205);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2010,'The Twilight Saga: Eclipse',706102828);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2014,'Dawn of the Planet of the Apes',703545589);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2015,'Mission: Impossible - Rogue Nation',700868363);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2011,'Mission: Impossible - Ghost Protocol',694713230);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2011,'The Twilight Saga: Breaking Dawn, Part 1',689420051);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2009,'The Twilight Saga: New Moon',687557727);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (1994,'Forrest Gump',679857164);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2012,'The Hunger Games',677923379);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (1999,'The Sixth Sense',672806292);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2013,'Man of Steel',667999518);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2014,'Interstellar',665417894);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2011,'Kung Fu Panda 2',664837547);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2012,'Men in Black 3',654213485);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2014,'Big Hero 6',652127828);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2006,'Ice Age: The Meltdown',651899282);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2002,'Star Wars Ep. II: Attack of the Clones',648200000);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2003,'Pirates of the Caribbean: The Curse of the Black Pearl',634954103);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2013,'Thor: The Dark World',633360018);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2008,'Kung Fu Panda',631910531);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2011,'Fast Five',629969804);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2007,'Ratatouille',626549695);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2008,'Hancock',624234272);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2010,'Iron Man 2',623256345);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2004,'The Passion of the Christ',622420667);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (1997,'The Lost World: Jurassic Park',618626844);

Insert into movies (YEAR_OF_RELEASE,NAME,GROSS_SALES) values (2014,'How to Train Your Dragon 2',616102924);

alter table movies add primary key ( name );

select count(*) from movies;

-- For these functions, you will get different (better) results than in the video, because we are using more data.  We dont use so much in the video due to limited screen space.
select name, gross_sales,
       100*cume_dist() over ( order by gross_sales ) as cumedist
from movies
order by 2,name;

select name, gross_sales,
       100*percent_rank() over ( order by gross_sales ) as pctrank
from movies
order by 2,name;

select name, gross_sales,
       ntile(4) over ( order by gross_sales ) as quartile
from movies
order by 2,name;

select name, gross_sales,
       ntile(4) over ( order by gross_sales desc ) as quartile
from movies
order by 2,name;

