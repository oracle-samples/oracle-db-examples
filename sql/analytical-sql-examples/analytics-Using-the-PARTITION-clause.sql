REM   Script: Analytics - Using the PARTITION clause
REM   SQL from the KISS (Keep It Simply SQL) Analytic video series by Developer Advocate Connor McDonald. This script is the first look at the partition clause.

Run this script standalone, or take it as part of the complete Analytics class at https://tinyurl.com/devgym-classes

drop table countries purge;

create table countries ( name varchar2(50), continent varchar2(30), population int );

begin 
insert into countries values ('Afghanistan',initcap('ASIA'),27101365); 
insert into countries values ('Albania',initcap('EUROPE'),2893005); 
insert into countries values ('Algeria',initcap('AFRICA'),40400000); 
insert into countries values ('Andorra',initcap('EUROPE'),76949); 
insert into countries values ('Angola',initcap('AFRICA'),24383301); 
insert into countries values ('Antigua and Barbuda',initcap('NORTH AMERICA'),86295); 
insert into countries values ('Argentina',initcap('SOUTH AMERICA'),43590400); 
insert into countries values ('Armenia',initcap('EUROPE'),3004000); 
insert into countries values ('Australia',initcap('OCEANIA'),24016400); 
insert into countries values ('Austria',initcap('EUROPE'),8662588); 
insert into countries values ('Azerbaijan',initcap('EUROPE'),9687300); 
insert into countries values ('Bahamas',initcap('NORTH AMERICA'),393000); 
insert into countries values ('Bahrain',initcap('ASIA'),1404900); 
insert into countries values ('Bangladesh',initcap('ASIA'),159663000); 
insert into countries values ('Barbados',initcap('NORTH AMERICA'),285000); 
insert into countries values ('Belarus',initcap('EUROPE'),9494200); 
insert into countries values ('Belgium',initcap('EUROPE'),11291746); 
insert into countries values ('Belize',initcap('NORTH AMERICA'),368310); 
insert into countries values ('Benin',initcap('AFRICA'),10653654); 
insert into countries values ('Bhutan',initcap('ASIA'),768960); 
insert into countries values ('Bolivia',initcap('SOUTH AMERICA'),10985059); 
insert into countries values ('Bosnia and Herzegovina',initcap('EUROPE'),3791622); 
insert into countries values ('Botswana',initcap('AFRICA'),2141206); 
insert into countries values ('Brazil',initcap('SOUTH AMERICA'),205444000); 
insert into countries values ('Brunei',initcap('ASIA'),411900); 
insert into countries values ('Bulgaria',initcap('EUROPE'),7202198); 
insert into countries values ('Burkina',initcap('AFRICA'),18450494); 
insert into countries values ('Burundi',initcap('AFRICA'),10114505); 
insert into countries values ('Cambodia',initcap('ASIA'),15626444); 
insert into countries values ('Cameroon',initcap('AFRICA'),23924000); 
insert into countries values ('Canada',initcap('NORTH AMERICA'),35985751); 
insert into countries values ('Cape Verde',initcap('AFRICA'),531239); 
insert into countries values ('Central African Republic',initcap('AFRICA'),4998000); 
insert into countries values ('Chad',initcap('AFRICA'),14497000); 
insert into countries values ('Chile',initcap('SOUTH AMERICA'),18191900); 
insert into countries values ('China',initcap('ASIA'),1374150000); 
insert into countries values ('Colombia',initcap('SOUTH AMERICA'),48470000); 
insert into countries values ('Comoros',initcap('AFRICA'),806153); 
insert into countries values ('Congo',initcap('AFRICA'),85026000); 
insert into countries values ('Costa Rica',initcap('NORTH AMERICA'),4832234); 
insert into countries values ('Croatia',initcap('EUROPE'),4225316); 
insert into countries values ('Cuba',initcap('NORTH AMERICA'),11238317); 
insert into countries values ('Cyprus',initcap('EUROPE'),847000); 
insert into countries values ('Czech Republic',initcap('EUROPE'),10541466); 
insert into countries values ('Denmark',initcap('EUROPE'),5699220); 
insert into countries values ('Djibouti',initcap('AFRICA'),900000); 
insert into countries values ('Dominica',initcap('NORTH AMERICA'),71293); 
insert into countries values ('Dominican Republic',initcap('NORTH AMERICA'),10075045); 
insert into countries values ('East Timor',initcap('ASIA'),1167242); 
insert into countries values ('Ecuador',initcap('SOUTH AMERICA'),16278844); 
insert into countries values ('Egypt',initcap('AFRICA'),90174100); 
insert into countries values ('El Salvador',initcap('NORTH AMERICA'),6520675); 
insert into countries values ('Equatorial Guinea',initcap('AFRICA'),1222442); 
insert into countries values ('Eritrea',initcap('AFRICA'),5352000); 
insert into countries values ('Estonia',initcap('EUROPE'),1313271); 
insert into countries values ('Ethiopia',initcap('AFRICA'),92206000); 
insert into countries values ('Fiji',initcap('OCEANIA'),867000); 
insert into countries values ('Finland',initcap('EUROPE'),5496275); 
insert into countries values ('France',initcap('EUROPE'),66539000); 
insert into countries values ('Gabon',initcap('AFRICA'),1802278); 
insert into countries values ('Georgia',initcap('EUROPE'),3729500); 
insert into countries values ('Germany',initcap('EUROPE'),81292400); 
insert into countries values ('Ghana',initcap('AFRICA'),27043093); 
insert into countries values ('Greece',initcap('EUROPE'),10846979); 
insert into countries values ('Grenada',initcap('NORTH AMERICA'),103328); 
insert into countries values ('Guatemala',initcap('NORTH AMERICA'),16176133); 
insert into countries values ('Guinea',initcap('AFRICA'),12947000); 
insert into countries values ('Guinea-Bissau',initcap('AFRICA'),1547777); 
insert into countries values ('Guyana',initcap('SOUTH AMERICA'),746900); 
insert into countries values ('Haiti',initcap('NORTH AMERICA'),11078033); 
insert into countries values ('Honduras',initcap('NORTH AMERICA'),8576532); 
insert into countries values ('Hungary',initcap('EUROPE'),9849000); 
insert into countries values ('Iceland',initcap('EUROPE'),331310); 
insert into countries values ('India',initcap('ASIA'),1282600000); 
insert into countries values ('Indonesia',initcap('ASIA'),258705000); 
insert into countries values ('Iran',initcap('ASIA'),78916000); 
insert into countries values ('Iraq',initcap('ASIA'),36575000); 
insert into countries values ('Ireland',initcap('EUROPE'),4635400); 
insert into countries values ('Israel',initcap('ASIA'),8462000); 
insert into countries values ('Italy',initcap('EUROPE'),60685487); 
insert into countries values ('Ivory Coast',initcap('AFRICA'),22671331); 
insert into countries values ('Jamaica',initcap('NORTH AMERICA'),2723246); 
insert into countries values ('Japan',initcap('ASIA'),126880000); 
insert into countries values ('Jordan',initcap('ASIA'),7748000); 
insert into countries values ('Kazakhstan',initcap('ASIA'),17630700); 
insert into countries values ('Kenya',initcap('AFRICA'),47251000); 
insert into countries values ('Kiribati',initcap('OCEANIA'),113400); 
insert into countries values ('Korea, North',initcap('ASIA'),25281000); 
insert into countries values ('Korea, South',initcap('ASIA'),51529338); 
insert into countries values ('Kyrgyzstan',initcap('ASIA'),5975000); 
insert into countries values ('Laos',initcap('ASIA'),6472400); 
insert into countries values ('Latvia',initcap('EUROPE'),1973700); 
insert into countries values ('Lebanon',initcap('ASIA'),4168000); 
insert into countries values ('Lesotho',initcap('AFRICA'),1894194); 
insert into countries values ('Liberia',initcap('AFRICA'),4615000); 
insert into countries values ('Libya',initcap('AFRICA'),6330000); 
insert into countries values ('Liechtenstein',initcap('EUROPE'),37370); 
insert into countries values ('Lithuania',initcap('EUROPE'),2890679); 
insert into countries values ('Luxembourg',initcap('EUROPE'),562958); 
insert into countries values ('Macedonia',initcap('EUROPE'),2069172); 
insert into countries values ('Madagascar',initcap('AFRICA'),22434363); 
insert into countries values ('Malawi',initcap('AFRICA'),16832910); 
insert into countries values ('Malaysia',initcap('ASIA'),30819500); 
insert into countries values ('Maldives',initcap('ASIA'),341256); 
insert into countries values ('Mali',initcap('AFRICA'),18135000); 
insert into countries values ('Malta',initcap('EUROPE'),445426); 
insert into countries values ('Marshall Islands',initcap('OCEANIA'),54880); 
insert into countries values ('Mauritania',initcap('AFRICA'),3718678); 
insert into countries values ('Mauritius',initcap('AFRICA'),1262879); 
insert into countries values ('Mexico',initcap('NORTH AMERICA'),122273500); 
insert into countries values ('Moldova',initcap('EUROPE'),3555200); 
insert into countries values ('Monaco',initcap('EUROPE'),37800); 
insert into countries values ('Mongolia',initcap('ASIA'),3059684); 
insert into countries values ('Montenegro',initcap('EUROPE'),621810); 
insert into countries values ('Morocco',initcap('AFRICA'),33337529); 
insert into countries values ('Mozambique',initcap('AFRICA'),26423700); 
insert into countries values ('Myanmar',initcap('ASIA'),54363000); 
insert into countries values ('Namibia',initcap('AFRICA'),2324400); 
insert into countries values ('Nauru',initcap('OCEANIA'),10084); 
insert into countries values ('Nepal',initcap('ASIA'),28431500); 
insert into countries values ('Netherlands',initcap('EUROPE'),16981400); 
insert into countries values ('New Zealand',initcap('OCEANIA'),4645120); 
insert into countries values ('Nicaragua',initcap('NORTH AMERICA'),6198154); 
insert into countries values ('Niger',initcap('AFRICA'),20715000); 
insert into countries values ('Nigeria',initcap('AFRICA'),186988000); 
insert into countries values ('Norway',initcap('EUROPE'),5214890); 
insert into countries values ('Oman',initcap('ASIA'),4319745); 
insert into countries values ('Pakistan',initcap('ASIA'),192420472); 
insert into countries values ('Palau',initcap('OCEANIA'),17950); 
insert into countries values ('Panama',initcap('NORTH AMERICA'),3764166); 
insert into countries values ('Papua New Guinea',initcap('OCEANIA'),8083700); 
insert into countries values ('Paraguay',initcap('SOUTH AMERICA'),7112594); 
insert into countries values ('Peru',initcap('SOUTH AMERICA'),31488700); 
insert into countries values ('Philippines',initcap('ASIA'),102612900); 
insert into countries values ('Poland',initcap('EUROPE'),38484000); 
insert into countries values ('Portugal',initcap('EUROPE'),10374822); 
insert into countries values ('Qatar',initcap('ASIA'),2463460); 
insert into countries values ('Romania',initcap('EUROPE'),19942642); 
insert into countries values ('Russia',initcap('ASIA'),146491330); 
insert into countries values ('Rwanda',initcap('AFRICA'),11553188); 
insert into countries values ('Saint Kitts and Nevis',initcap('NORTH AMERICA'),46204); 
insert into countries values ('Saint Lucia',initcap('NORTH AMERICA'),186000); 
insert into countries values ('Saint Vincent and the Grenadines',initcap('NORTH AMERICA'),109991); 
insert into countries values ('Samoa',initcap('OCEANIA'),187820); 
insert into countries values ('San Marino',initcap('EUROPE'),32968); 
insert into countries values ('Sao Tome and Principe',initcap('AFRICA'),187356); 
insert into countries values ('Saudi Arabia',initcap('ASIA'),32248200); 
insert into countries values ('Senegal',initcap('AFRICA'),14354690); 
insert into countries values ('Serbia',initcap('EUROPE'),7114393); 
insert into countries values ('Seychelles',initcap('AFRICA'),91400); 
insert into countries values ('Sierra Leone',initcap('AFRICA'),6592000); 
insert into countries values ('Singapore',initcap('ASIA'),5535000); 
insert into countries values ('Slovakia',initcap('EUROPE'),5424058); 
insert into countries values ('Slovenia',initcap('EUROPE'),2069223); 
insert into countries values ('Solomon Islands',initcap('OCEANIA'),642000); 
insert into countries values ('Somalia',initcap('AFRICA'),11079000); 
insert into countries values ('South Africa',initcap('AFRICA'),54956900); 
insert into countries values ('South Sudan',initcap('AFRICA'),11892934); 
insert into countries values ('Spain',initcap('EUROPE'),46423064); 
insert into countries values ('Sri Lanka',initcap('ASIA'),20966000); 
insert into countries values ('Sudan',initcap('AFRICA'),39598700); 
insert into countries values ('Suriname',initcap('SOUTH AMERICA'),534189); 
insert into countries values ('Swaziland',initcap('AFRICA'),1132657); 
insert into countries values ('Sweden',initcap('EUROPE'),9838480); 
insert into countries values ('Switzerland',initcap('EUROPE'),8306200); 
insert into countries values ('Syria',initcap('ASIA'),23558929); 
insert into countries values ('Tajikistan',initcap('ASIA'),8352000); 
insert into countries values ('Tanzania',initcap('AFRICA'),55155000); 
insert into countries values ('Thailand',initcap('ASIA'),65218156); 
insert into countries values ('Togo',initcap('AFRICA'),7143000); 
insert into countries values ('Tonga',initcap('OCEANIA'),103252); 
insert into countries values ('Trinidad and Tobago',initcap('NORTH AMERICA'),1349667); 
insert into countries values ('Tunisia',initcap('AFRICA'),10982754); 
insert into countries values ('Turkey',initcap('ASIA'),77695904); 
insert into countries values ('Turkmenistan',initcap('ASIA'),4751120); 
insert into countries values ('Tuvalu',initcap('OCEANIA'),10640); 
insert into countries values ('Uganda',initcap('AFRICA'),34856813); 
insert into countries values ('Ukraine',initcap('EUROPE'),42789472); 
insert into countries values ('United Arab Emirates',initcap('ASIA'),9267000); 
insert into countries values ('United Kingdom',initcap('EUROPE'),64800000); 
insert into countries values ('United States',initcap('NORTH AMERICA'),322586000); 
insert into countries values ('Uruguay',initcap('SOUTH AMERICA'),3480222); 
insert into countries values ('Uzbekistan',initcap('ASIA'),31022500); 
insert into countries values ('Vanuatu',initcap('OCEANIA'),277500); 
insert into countries values ('Vatican City',initcap('EUROPE'),839); 
insert into countries values ('Venezuela',initcap('SOUTH AMERICA'),31028700); 
insert into countries values ('Vietnam',initcap('ASIA'),91700000); 
insert into countries values ('Yemen',initcap('ASIA'),25956000); 
insert into countries values ('Zambia',initcap('AFRICA'),15933883); 
insert into countries values ('Zimbabwe',initcap('AFRICA'),15967000); 
 
commit; 
end; 
/

select * 
from countries 
order by continent, name;

select * 
from ( 
  select c.*, 
         row_number() over ( order by population desc) as pop_rank 
  from   countries c 
  where  continent = 'Africa' 
) 
where pop_rank <= 3;

select * 
from ( 
  select c.*, 
         row_number() over ( order by population desc) as pop_rank 
  from   countries c 
  where  continent = 'Oceania' 
) 
where pop_rank <= 3;

select * 
from ( 
  select c.*, 
         row_number() over ( order by population desc) as pop_rank 
  from   countries c 
  where  continent = 'Europe' 
) 
where pop_rank <= 3;

select * 
from ( 
  select c.*, 
         row_number() over (  
             partition by continent 
             order by population desc) as pop_rank 
  from   countries c 
) 
where pop_rank <= 3;

