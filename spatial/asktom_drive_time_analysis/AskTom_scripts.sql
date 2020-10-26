--
-- Stage 1 GC and Reverse GC
--

-- Convert location information into network representation

-- geocoding
SELECT SDO_GCDR.GEOCODE('here_sf', SDO_KEYWORDARRAY('500 oracle pky','redwood city, CA'), 'US', 'RELAX_BASE_NAME') addr FROM DUAL;

with
part1 as (
    SELECT SDO_GCDR.GEOCODE('here_sf', SDO_KEYWORDARRAY('500 oracle pky','redwood city, CA'), 'US', 'RELAX_BASE_NAME') addr FROM DUAL
)
select a.addr.edgeid,  a.addr.percent, a.addr.side, a.addr.longitude, a.addr.latitude from part1 a;


-- reverse geocode with longitude,latitude
with
part1 as (
    SELECT SDO_GCDR.REVERSE_GEOCODE('here_sf', SDO_GEOMETRY(2001, 8307, SDO_POINT_TYPE(-122.26109, 37.5313, NULL), NULL, NULL),'US') addr FROM DUAL
)
select a.addr.edgeid,  a.addr.percent, a.addr.side, a.addr.longitude, a.addr.latitude from part1 a;


-- examples
-- get all geocoded result of a table of streetaddress of buffer centers
select * from sf_stores_streetaddress order by store_id;

with
part1 as (
    SELECT b.STORE_ID, SDO_GCDR.GEOCODE('here_sf', SDO_KEYWORDARRAY(b.STREETADDRESS), 'US', 'RELAX_BASE_NAME') addr
    FROM SF_STORES_STREETADDRESS b
)
select a.store_id, a.addr.edgeid,  a.addr.percent, a.addr.side, a.addr.longitude, a.addr.latitude
from part1 a
order by a.store_id;

-- transfer edgeid, percentage, and side to link_id
with
part1 as (
    SELECT b.STORE_ID, SDO_GCDR.GEOCODE('here_sf', SDO_KEYWORDARRAY(b.STREETADDRESS), 'US', 'RELAX_BASE_NAME') addr
    FROM SF_STORES_STREETADDRESS b
)
SELECT a.store_id, a.addr.longitude longitude, a.addr.latitude latitude, a.addr.side side,
case
    when a.addr.side = 'L' then -a.addr.edgeid
    else a.addr.edgeid
end as link_id,
case
    when a.addr.side = 'L' then 1-a.addr.percent
    else a.addr.percent
end as percent
from part1 a
order by a.store_id;


--
-- Stage 2 , Create Network Buffers
--

-- Generate network buffer tables network buffer prefix: ('SF') in NDM java api

--
-- now create network buffers with NDM Java Code
--

-- 16g RAM linux box
-- ~1s per buffer including analysis and persistence for 10-minute-drive.

-- stoer buffers

-- describe network buffer tables

-- metadata table
-- buffer id, radius and direction
select * from sf_nbr$ order by buffer_id;

-- metadata table
-- buffer network representation
select * from SF_NBCL$ order by buffer_id;


-- coverage table:
-- network buffer covered link table schema
select * from SF_NBL$ where rownum < 20;

-- number of covered links of each buffer (10-minute-drive)
select buffer_id, count(*) from SF_nbl$ group by buffer_id order by buffer_id;


-- 10 min. path buffer used in the second demo:

-- metadata
-- buffer_id, radius, direction
select * from path_10m_nbr$ order by buffer_id;

-- buffer centers for each buffer
select buffer_id,count(*) from PATH_10M_NBcL$ group by buffer_id order by buffer_id;

-- no of covered links for each 10-minute buffer
select buffer_id, count(*) from PATH_10M_NBL$ group by buffer_id order by buffer_id;




--
-- Stage 3, Query Network Buffers
--

-- queries on network buffer table

-- get cost to one specific buffer centers of a given location (link_id, percentage)
SELECT buffer_id, MIN(start_cost+(0.95-start_percentage)*(end_cost-start_cost)/(end_percentage-start_percentage)) cost
FROM SF_NBl$
WHERE link_id=945669955
AND buffer_id = 1
AND (0.95-start_percentage)*(end_percentage-start_percentage)>=0
GROUP BY buffer_id;

-- get costs to all buffer centers of a given location (link_id, percentage)
SELECT buffer_id, MIN(start_cost+(0.95-start_percentage)*(end_cost-start_cost)/(end_percentage-start_percentage)) cost
FROM SF_NBl$
WHERE link_id=945669955
AND (0.95-start_percentage)*(end_percentage-start_percentage)>=0
GROUP BY buffer_id
ORDER BY COST;

-- get links of the shortest path from a given location to a specific buffer center
select buffer_id, link_id, prev_link_id from sf_nbl$
where buffer_id = 1
start with link_id = 799415310
connect by prior prev_link_id = link_id and
           prior start_cost = end_cost  and
           prior buffer_id = buffer_id
order by start_cost;

-- get path geometry from a given location to a buffer center
with
part1 as(                                       -- get links of the path
select link_id from sf_nbl$
where buffer_id = 1
start with link_id = 799415310
connect by prior prev_link_id = link_id and
           prior start_cost = end_cost  and
           prior buffer_id = buffer_id
order by start_cost
),
part2 as(                                       -- get geometry of each link of the path
    select a.link_id, b.geometry
    from part1 a, here_sf_net_link$ b
    where a.link_id = b.link_id
)
select SDO_AGGR_CONCAT_LINES(b.geometry) path   -- create path geometry
from part2 b;


-- get path geometry vertices from a given location to a buffer center
with
part1 as(                                       -- get links of the path
select link_id from sf_nbl$
where buffer_id = 1
start with link_id = 799415310
connect by prior prev_link_id = link_id and
           prior start_cost = end_cost  and
           prior buffer_id = buffer_id
order by start_cost
),
part2 as(                                       -- get geometry of each link of the path
    select a.link_id, b.geometry
    from part1 a, here_sf_net_link$ b
    where a.link_id = b.link_id
), 
part3 as (
select SDO_AGGR_CONCAT_LINES(b.geometry) path   -- create path geometry
from part2 b
)
select t.x,t.y,t.id from
part3 a, table(sdo_util.getvertices(a.path)) t   -- create path geometry
order by t.id ;

