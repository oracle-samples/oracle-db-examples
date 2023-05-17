REM   Script: Analytics - Window boundaries
REM   SQL from the KISS (Keep It Simply SQL) Analytic video series by Developer Advocate Connor McDonald. This script demonstrates the first_value / last_value functions for accessing window boundaries.

Run this script standalone, or take it as part of the complete Analytics class at https://tinyurl.com/devgym-classes

alter session set nls_date_format = 'DD-MON-YYYY';

drop table life_expectancy purge;

create table life_expectancy ( recorded_year date, age number(6,2) );

insert into life_expectancy values (date '1543-01-01',33.94);

insert into life_expectancy values (date '1548-01-01',38.82);

insert into life_expectancy values (date '1553-01-01',39.59);

insert into life_expectancy values (date '1558-01-01',22.38);

insert into life_expectancy values (date '1563-01-01',36.66);

insert into life_expectancy values (date '1568-01-01',39.67);

insert into life_expectancy values (date '1573-01-01',41.06);

insert into life_expectancy values (date '1578-01-01',41.56);

insert into life_expectancy values (date '1583-01-01',42.7);

insert into life_expectancy values (date '1588-01-01',37.05);

insert into life_expectancy values (date '1593-01-01',38.05);

insert into life_expectancy values (date '1598-01-01',37.82);

insert into life_expectancy values (date '1603-01-01',38.53);

insert into life_expectancy values (date '1608-01-01',39.59);

insert into life_expectancy values (date '1613-01-01',36.79);

insert into life_expectancy values (date '1618-01-01',40.31);

insert into life_expectancy values (date '1623-01-01',33.39);

insert into life_expectancy values (date '1628-01-01',39.69);

insert into life_expectancy values (date '1633-01-01',39.72);

insert into life_expectancy values (date '1638-01-01',34.03);

insert into life_expectancy values (date '1643-01-01',36.32);

insert into life_expectancy values (date '1648-01-01',39.74);

insert into life_expectancy values (date '1653-01-01',39.14);

insert into life_expectancy values (date '1658-01-01',33.04);

insert into life_expectancy values (date '1663-01-01',33.27);

insert into life_expectancy values (date '1668-01-01',32.48);

insert into life_expectancy values (date '1673-01-01',37.41);

insert into life_expectancy values (date '1678-01-01',32.4);

insert into life_expectancy values (date '1683-01-01',31.27);

insert into life_expectancy values (date '1688-01-01',35.93);

insert into life_expectancy values (date '1693-01-01',36.35);

insert into life_expectancy values (date '1698-01-01',38.06);

insert into life_expectancy values (date '1703-01-01',38.47);

insert into life_expectancy values (date '1708-01-01',38.5);

insert into life_expectancy values (date '1713-01-01',36.89);

insert into life_expectancy values (date '1718-01-01',35.75);

insert into life_expectancy values (date '1723-01-01',35.49);

insert into life_expectancy values (date '1728-01-01',25.34);

insert into life_expectancy values (date '1733-01-01',36.34);

insert into life_expectancy values (date '1738-01-01',35.26);

insert into life_expectancy values (date '1743-01-01',34.27);

insert into life_expectancy values (date '1748-01-01',36.47);

insert into life_expectancy values (date '1753-01-01',39.77);

insert into life_expectancy values (date '1758-01-01',38.12);

insert into life_expectancy values (date '1763-01-01',35.37);

insert into life_expectancy values (date '1768-01-01',36.19);

insert into life_expectancy values (date '1773-01-01',39.09);

insert into life_expectancy values (date '1778-01-01',37.74);

insert into life_expectancy values (date '1783-01-01',35.81);

insert into life_expectancy values (date '1788-01-01',38.97);

insert into life_expectancy values (date '1793-01-01',37.92);

insert into life_expectancy values (date '1798-01-01',38.93);

insert into life_expectancy values (date '1803-01-01',40.02);

insert into life_expectancy values (date '1808-01-01',40.58);

insert into life_expectancy values (date '1813-01-01',41.25);

insert into life_expectancy values (date '1818-01-01',40.84);

insert into life_expectancy values (date '1823-01-01',40.47);

insert into life_expectancy values (date '1828-01-01',41.43);

insert into life_expectancy values (date '1833-01-01',40.89);

insert into life_expectancy values (date '1838-01-01',40.56);

insert into life_expectancy values (date '1842-01-01',40.995);

insert into life_expectancy values (date '1843-01-01',41.56);

insert into life_expectancy values (date '1844-01-01',41.24);

insert into life_expectancy values (date '1845-01-01',42.17);

insert into life_expectancy values (date '1846-01-01',40.15);

insert into life_expectancy values (date '1847-01-01',38.515);

insert into life_expectancy values (date '1848-01-01',39.89);

insert into life_expectancy values (date '1849-01-01',37.68);

insert into life_expectancy values (date '1850-01-01',42.77);

insert into life_expectancy values (date '1851-01-01',40.95);

insert into life_expectancy values (date '1852-01-01',40.41);

insert into life_expectancy values (date '1853-01-01',39.985);

insert into life_expectancy values (date '1854-01-01',39.48);

insert into life_expectancy values (date '1855-01-01',40.74);

insert into life_expectancy values (date '1856-01-01',42.47);

insert into life_expectancy values (date '1857-01-01',40.925);

insert into life_expectancy values (date '1858-01-01',39.545);

insert into life_expectancy values (date '1859-01-01',40.405);

insert into life_expectancy values (date '1860-01-01',41.945);

insert into life_expectancy values (date '1861-01-01',41.62);

insert into life_expectancy values (date '1862-01-01',42.13);

insert into life_expectancy values (date '1863-01-01',40.37);

insert into life_expectancy values (date '1864-01-01',39.585);

insert into life_expectancy values (date '1865-01-01',39.75);

insert into life_expectancy values (date '1866-01-01',40.085);

insert into life_expectancy values (date '1867-01-01',41.995);

insert into life_expectancy values (date '1868-01-01',41.7);

insert into life_expectancy values (date '1869-01-01',41.34);

insert into life_expectancy values (date '1870-01-01',40.605);

insert into life_expectancy values (date '1871-01-01',41.135);

insert into life_expectancy values (date '1872-01-01',42.72);

insert into life_expectancy values (date '1873-01-01',43.29);

insert into life_expectancy values (date '1874-01-01',42.105);

insert into life_expectancy values (date '1875-01-01',41.45);

insert into life_expectancy values (date '1876-01-01',42.665);

insert into life_expectancy values (date '1877-01-01',43.69);

insert into life_expectancy values (date '1878-01-01',42.04);

insert into life_expectancy values (date '1879-01-01',43.505);

insert into life_expectancy values (date '1880-01-01',42.975);

insert into life_expectancy values (date '1881-01-01',45.055);

insert into life_expectancy values (date '1882-01-01',43.985);

insert into life_expectancy values (date '1883-01-01',44.015);

insert into life_expectancy values (date '1884-01-01',43.635);

insert into life_expectancy values (date '1885-01-01',44.57);

insert into life_expectancy values (date '1886-01-01',44.585);

insert into life_expectancy values (date '1887-01-01',45.08);

insert into life_expectancy values (date '1888-01-01',46.28);

insert into life_expectancy values (date '1889-01-01',45.93);

insert into life_expectancy values (date '1890-01-01',44.12);

insert into life_expectancy values (date '1891-01-01',44.43);

insert into life_expectancy values (date '1892-01-01',45.59);

insert into life_expectancy values (date '1893-01-01',44.68);

insert into life_expectancy values (date '1894-01-01',48.275);

insert into life_expectancy values (date '1895-01-01',45.41);

insert into life_expectancy values (date '1896-01-01',47.07);

insert into life_expectancy values (date '1897-01-01',46.445);

insert into life_expectancy values (date '1898-01-01',46.14);

insert into life_expectancy values (date '1899-01-01',45.245);

insert into life_expectancy values (date '1900-01-01',45.62);

insert into life_expectancy values (date '1901-01-01',46.93);

insert into life_expectancy values (date '1902-01-01',48.355);

insert into life_expectancy values (date '1903-01-01',49.54);

insert into life_expectancy values (date '1904-01-01',48.145);

insert into life_expectancy values (date '1905-01-01',49.92);

insert into life_expectancy values (date '1906-01-01',49.595);

insert into life_expectancy values (date '1907-01-01',50.565);

insert into life_expectancy values (date '1908-01-01',51.02);

insert into life_expectancy values (date '1909-01-01',51.67);

insert into life_expectancy values (date '1910-01-01',53.255);

insert into life_expectancy values (date '1911-01-01',51.225);

insert into life_expectancy values (date '1912-01-01',54.31);

insert into life_expectancy values (date '1913-01-01',53.355);

insert into life_expectancy values (date '1914-01-01',53.21);

insert into life_expectancy values (date '1915-01-01',51.205);

insert into life_expectancy values (date '1916-01-01',54.24);

insert into life_expectancy values (date '1917-01-01',54.155);

insert into life_expectancy values (date '1918-01-01',47.275);

insert into life_expectancy values (date '1919-01-01',54.31);

insert into life_expectancy values (date '1920-01-01',57.255);

insert into life_expectancy values (date '1921-01-01',58.085);

insert into life_expectancy values (date '1922-01-01',57.03);

insert into life_expectancy values (date '1923-01-01',59.31);

insert into life_expectancy values (date '1924-01-01',58.08);

insert into life_expectancy values (date '1925-01-01',58.43);

insert into life_expectancy values (date '1926-01-01',59.57);

insert into life_expectancy values (date '1927-01-01',58.96);

insert into life_expectancy values (date '1928-01-01',59.92);

insert into life_expectancy values (date '1929-01-01',57.63);

insert into life_expectancy values (date '1930-01-01',60.78);

insert into life_expectancy values (date '1931-01-01',60.01);

insert into life_expectancy values (date '1932-01-01',60.53);

insert into life_expectancy values (date '1933-01-01',60.58);

insert into life_expectancy values (date '1934-01-01',61.31);

insert into life_expectancy values (date '1935-01-01',61.96);

insert into life_expectancy values (date '1936-01-01',61.76);

insert into life_expectancy values (date '1937-01-01',61.8);

insert into life_expectancy values (date '1938-01-01',63.21);

insert into life_expectancy values (date '1939-01-01',63.61);

insert into life_expectancy values (date '1940-01-01',60.88);

insert into life_expectancy values (date '1941-01-01',61.35);

insert into life_expectancy values (date '1942-01-01',63.99);

insert into life_expectancy values (date '1943-01-01',64.01);

insert into life_expectancy values (date '1944-01-01',64.81);

insert into life_expectancy values (date '1945-01-01',65.75);

insert into life_expectancy values (date '1946-01-01',66.34);

insert into life_expectancy values (date '1947-01-01',66.31);

insert into life_expectancy values (date '1948-01-01',68.39);

insert into life_expectancy values (date '1949-01-01',68.11);

insert into life_expectancy values (date '1950-01-01',68.63);

insert into life_expectancy values (date '1951-01-01',68.24);

insert into life_expectancy values (date '1952-01-01',69.54);

insert into life_expectancy values (date '1953-01-01',69.8);

insert into life_expectancy values (date '1954-01-01',70.17);

insert into life_expectancy values (date '1955-01-01',70.14);

insert into life_expectancy values (date '1956-01-01',70.4);

insert into life_expectancy values (date '1957-01-01',70.53);

insert into life_expectancy values (date '1958-01-01',70.7);

insert into life_expectancy values (date '1959-01-01',70.82);

insert into life_expectancy values (date '1960-01-01',71.04);

insert into life_expectancy values (date '1961-01-01',70.79);

insert into life_expectancy values (date '1962-01-01',70.85);

insert into life_expectancy values (date '1963-01-01',70.76);

insert into life_expectancy values (date '1964-01-01',71.55);

insert into life_expectancy values (date '1965-01-01',71.52);

insert into life_expectancy values (date '1966-01-01',71.44);

insert into life_expectancy values (date '1967-01-01',72.07);

insert into life_expectancy values (date '1968-01-01',71.69);

insert into life_expectancy values (date '1969-01-01',71.66);

insert into life_expectancy values (date '1970-01-01',71.9);

insert into life_expectancy values (date '1971-01-01',72.23);

insert into life_expectancy values (date '1972-01-01',72);

insert into life_expectancy values (date '1973-01-01',72.19);

insert into life_expectancy values (date '1974-01-01',72.38);

insert into life_expectancy values (date '1975-01-01',72.65);

insert into life_expectancy values (date '1976-01-01',72.64);

insert into life_expectancy values (date '1977-01-01',73.12);

insert into life_expectancy values (date '1978-01-01',73.06);

insert into life_expectancy values (date '1979-01-01',73.16);

insert into life_expectancy values (date '1980-01-01',73.59);

insert into life_expectancy values (date '1981-01-01',73.92);

insert into life_expectancy values (date '1982-01-01',74.04);

insert into life_expectancy values (date '1983-01-01',74.29);

insert into life_expectancy values (date '1984-01-01',74.68);

insert into life_expectancy values (date '1985-01-01',74.53);

insert into life_expectancy values (date '1986-01-01',74.8);

insert into life_expectancy values (date '1987-01-01',75.15);

insert into life_expectancy values (date '1988-01-01',75.26);

insert into life_expectancy values (date '1989-01-01',75.4);

insert into life_expectancy values (date '1990-01-01',75.74);

insert into life_expectancy values (date '1991-01-01',75.91);

insert into life_expectancy values (date '1992-01-01',76.3);

insert into life_expectancy values (date '1993-01-01',76.17);

insert into life_expectancy values (date '1994-01-01',76.72);

insert into life_expectancy values (date '1995-01-01',76.62);

insert into life_expectancy values (date '1996-01-01',76.88);

insert into life_expectancy values (date '1997-01-01',77.14);

insert into life_expectancy values (date '1998-01-01',77.28);

insert into life_expectancy values (date '1999-01-01',77.38);

insert into life_expectancy values (date '2000-01-01',77.86);

insert into life_expectancy values (date '2001-01-01',78.14);

insert into life_expectancy values (date '2002-01-01',78.26);

insert into life_expectancy values (date '2003-01-01',78.35);

insert into life_expectancy values (date '2004-01-01',78.93);

insert into life_expectancy values (date '2005-01-01',79.13);

insert into life_expectancy values (date '2006-01-01',79.37);

insert into life_expectancy values (date '2007-01-01',79.56);

insert into life_expectancy values (date '2008-01-01',79.68);

insert into life_expectancy values (date '2009-01-01',80.18);

insert into life_expectancy values (date '2010-01-01',80.41);

insert into life_expectancy values (date '2011-01-01',80.8);

commit


select * from  life_expectancy order by 1;

select  
  recorded_year, age,
  first_value(age) over
    ( order by recorded_year
      range between interval '5' year preceding 
            and interval '5' year following ) as first_val
from life_expectancy
order by 1;

select  
  recorded_year, age,
  first_value(age) over
    ( order by recorded_year
      range between interval '5' year preceding 
            and interval '5' year following ) as first_val,
  last_value(age) over
    ( order by recorded_year
      range between interval '5' year preceding 
            and interval '5' year following ) as last_val
from life_expectancy
order by 1;

select  
  recorded_year, age,
  first_value(age) over
    ( order by recorded_year
      range between interval '5' year preceding 
            and interval '5' year following ) as fv,
  min(age) over
    ( order by recorded_year
      range between interval '5' year preceding 
            and interval '5' year following ) as minv
from life_expectancy
order by 1;

select *
from 
(
  select  
    recorded_year, age,
    first_value(age) over
      ( order by recorded_year
        range between interval '5' year preceding 
              and interval '5' year following ) as fv,
    min(age) over
      ( order by recorded_year
        range between interval '5' year preceding 
              and interval '5' year following ) as minv
  from life_expectancy
)
where fv != minv
order by 1;

