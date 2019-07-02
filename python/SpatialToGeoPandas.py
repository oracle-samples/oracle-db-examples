#------------------------------------------------------------------------------
# Copyright (c) 2018, 2019, Oracle and/or its affiliates. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# SpatialToGeoPandas.py
#   GeoPandas is a popular python library for working with geospatial data.
# GeoPandas extends the Pandas data analysis library with geospatial support
# using the Shapely library for geometry object support.
#
# See http://geopandas.org, https://pandas.pydata.org,
# and https://github.com/Toblerity/Shapely.
#
# This example shows how to bring geometries from Oracle Spatial (SDO_GEOMETRY
# data type) into GeoPandas and perform a simple spatial operation. While the
# spatial operation we perform in Python could have been performed in the
# Oracle database, this example targets use cases where Python with GeoPandas
# is being used to combine and work with geospatial data from numerous
# additional sources such as files and web services.
#
# This script requires cx_Oracle (5.3 and higher) as well as GeoPandas and its
# dependencies (see http://geopandas.org/install.html).
#------------------------------------------------------------------------------

from __future__ import print_function

import SampleEnv
import cx_Oracle
from shapely.wkb import loads
import geopandas as gpd

# create Oracle connection and cursor objects
connection = cx_Oracle.connect(SampleEnv.GetMainConnectString())
cursor = connection.cursor()

# enable autocommit to avoid the additional round trip to the database to
# perform a commit; this should not be used if multiple statements must be
# executed for a single transaction
connection.autocommit = True

# define output type handler to fetch LOBs, avoiding the second round trip to
# the database to read the LOB contents
def OutputTypeHandler(cursor, name, defaultType, size, precision, scale):
    if defaultType == cx_Oracle.BLOB:
        return cursor.var(cx_Oracle.LONG_BINARY, arraysize = cursor.arraysize)
connection.outputtypehandler = OutputTypeHandler

# drop and create table
print("Dropping and creating table...")
cursor.execute("""
        begin
            execute immediate 'drop table TestStates';
            exception when others then
                if sqlcode <> -942 then
                    raise;
                end if;
        end;""")
cursor.execute("""
        create table TestStates (
            state VARCHAR2(30) not null,
            geometry SDO_GEOMETRY not null
        )""")

# acquire types used for creating SDO_GEOMETRY objects
typeObj = connection.gettype("MDSYS.SDO_GEOMETRY")
elementInfoTypeObj = connection.gettype("MDSYS.SDO_ELEM_INFO_ARRAY")
ordinateTypeObj = connection.gettype("MDSYS.SDO_ORDINATE_ARRAY")

# define function for creating an SDO_GEOMETRY object
def CreateGeometryObj(*ordinates):
    geometry = typeObj.newobject()
    geometry.SDO_GTYPE = 2003
    geometry.SDO_SRID = 8307
    geometry.SDO_ELEM_INFO = elementInfoTypeObj.newobject()
    geometry.SDO_ELEM_INFO.extend([1, 1003, 1])
    geometry.SDO_ORDINATES = ordinateTypeObj.newobject()
    geometry.SDO_ORDINATES.extend(ordinates)
    return geometry

# create SDO_GEOMETRY objects for three adjacent states in the USA
geometryNevada = CreateGeometryObj(-114.052025, 37.103989, -114.049797,
        37.000423, -113.484375, 37, -112.898598, 37.000401,-112.539604,
        37.000683, -112, 37.000977, -111.412048, 37.001514, -111.133018,
        37.00079,-110.75, 37.003201, -110.5, 37.004265, -110.469505, 36.998001,
        -110, 36.997967, -109.044571,36.999088, -109.045143, 37.375,
        -109.042824, 37.484692, -109.040848, 37.881176, -109.041405,38.153027,
        -109.041107, 38.1647, -109.059402, 38.275501, -109.059296, 38.5,
        -109.058868, 38.719906,-109.051765, 39, -109.050095, 39.366699,
        -109.050697, 39.4977, -109.050499, 39.6605, -109.050156,40.222694,
        -109.047577, 40.653641, -109.0494, 41.000702, -109.2313, 41.002102,
        -109.534233,40.998184, -110, 40.997398, -110.047768, 40.997696, -110.5,
        40.994801, -111.045982, 40.998013,-111.045815, 41.251774, -111.045097,
        41.579899, -111.045944, 42.001633, -111.506493, 41.999588,-112.108742,
        41.997677, -112.16317, 41.996784, -112.172562, 41.996643, -112.192184,
        42.001244,-113, 41.998314, -113.875, 41.988091, -114.040871, 41.993805,
        -114.038803, 41.884899, -114.041306,41, -114.04586, 40.116997,
        -114.046295, 39.906101, -114.046898, 39.542801, -114.049026, 38.67741,
        -114.049339, 38.572968, -114.049095, 38.14864, -114.0476,
        37.80946,-114.05098, 37.746284, -114.051666, 37.604805, -114.052025,
        37.103989)
geometryWyoming = CreateGeometryObj(-111.045815, 41.251774, -111.045982,
        40.998013, -110.5, 40.994801, -110.047768, 40.997696, -110, 40.997398,
        -109.534233, 40.998184, -109.2313, 41.002102, -109.0494, 41.000702,
        -108.525368, 40.999634, -107.917793, 41.002071, -107.317177, 41.002956,
        -106.857178, 41.002697, -106.455704, 41.002167, -106.320587, 40.999153,
        -106.189987, 40.997604, -105.729874, 40.996906, -105.276604, 40.998188,
        -104.942848, 40.998226, -104.625, 41.00145, -104.052742, 41.001423,
        -104.051781, 41.39333, -104.052032, 41.564301, -104.052185, 41.697983,
        -104.052109, 42.001736, -104.052277, 42.611626, -104.052643, 43.000614,
        -104.054337, 43.47784, -104.054298, 43.503101, -104.055, 43.8535,
        -104.054108, 44.141102, -104.054001, 44.180401, -104.055458, 44.570877,
        -104.057205, 44.997444, -104.664658, 44.998631, -105.037872, 45.000359,
        -105.088867, 45.000462, -105.912819, 45.000957, -105.927612, 44.99366,
        -106.024239, 44.993591, -106.263, 44.993801, -107.054871, 44.996384,
        -107.133545, 45.000141, -107.911095, 45.001343, -108.248672, 44.999504,
        -108.620628, 45.000328, -109.082314, 44.999664, -109.102745, 45.005955,
        -109.797951, 45.002247, -110.000771, 45.003502, -110.10936, 45.003967,
        -110.198761, 44.99625, -110.286026, 44.99691, -110.361946, 45.000656,
        -110.402176, 44.993874, -110.5, 44.992355, -110.704506, 44.99239,
        -110.784241, 45.003021, -111.05442, 45.001392, -111.054558, 44.666336,
        -111.048203, 44.474144, -111.046272, 43.983456, -111.044724, 43.501213,
        -111.043846, 43.3158, -111.043381, 43.02013, -111.042786, 42.719578,
        -111.045967, 42.513187, -111.045944, 42.001633, -111.045097, 41.579899,
        -111.045815, 41.251774)
geometryColorado = CreateGeometryObj(-109.045143, 37.375, -109.044571,
        36.999088, -108.378571, 36.999516, -107.481133, 37, -107.420311, 37,
        -106.876701, 37.00013, -106.869209, 36.992416, -106.475639, 36.993748,
        -106.006058, 36.995327, -105.717834, 36.995823, -105.220055, 36.995144,
        -105.154488, 36.995239, -105.028671, 36.992702, -104.407616, 36.993446,
        -104.007324, 36.996216, -103.085617, 37.000244, -103.001709, 37.000084,
        -102.986488, 36.998505, -102.759384, 37, -102.69767, 36.995132,
        -102.041794, 36.993061, -102.041191, 37.389172, -102.04113, 37.644268,
        -102.041695, 37.738529, -102.043938, 38.262466, -102.044113, 38.268803,
        -102.04483, 38.615234, -102.044762, 38.697556, -102.046112, 39.047035,
        -102.046707, 39.133144, -102.049301, 39.568176, -102.049347, 39.574062,
        -102.051277, 40.00309, -102.051117, 40.34922, -102.051003, 40.440018,
        -102.050873, 40.697556, -102.050835, 40.749596, -102.051155, 41.002384,
        -102.620567, 41.002609, -102.652992, 41.002342, -103.382011, 41.00227,
        -103.574036, 41.001736, -104.052742, 41.001423, -104.625, 41.00145,
        -104.942848, 40.998226, -105.276604, 40.998188, -105.729874, 40.996906,
        -106.189987, 40.997604, -106.320587, 40.999153, -106.455704, 41.002167,
        -106.857178, 41.002697, -107.317177, 41.002956, -107.917793, 41.002071,
        -108.525368, 40.999634, -109.0494, 41.000702, -109.047577, 40.653641,
        -109.050156, 40.222694, -109.050499, 39.6605, -109.050697, 39.4977,
        -109.050095, 39.366699, -109.051765, 39, -109.058868, 38.719906,
        -109.059296, 38.5, -109.059402, 38.275501, -109.041107, 38.1647,
        -109.041405, 38.153027, -109.040848, 37.881176, -109.042824, 37.484692,
        -109.045143, 37.375)

# Insert rows for test states. If we were analyzing these geometries in Oracle
# we would also add Spatial metadata and indexes.  However in this example we
# are only storing the geometries so that we load them back into Python, so we
# will skip the metadata and indexes.
print("Adding rows to table...")
data = [
    ('Nevada', geometryNevada),
    ('Colorado', geometryColorado),
    ('Wyoming', geometryWyoming)
]
cursor.executemany('insert into TestStates values (:state, :obj)', data)

# We now have test geometries in Oracle Spatial (SDO_GEOMETRY) and will next
# bring them back into Python to analyze with GeoPandas. GeoPandas is able to
# consume geometries in the Well Known Text (WKT) and Well Known Binary (WKB)
# formats. Oracle database includes utility functions to return SDO_GEOMETRY as
# both WKT and WKB. Therefore we use that utility function in the query below
# to provide results in a format readily consumable by GeoPandas. These utility
# functions were introduced in Oracle 10g. We use WKB here; however the same
# process applies for WKT.
cursor.execute("""
        SELECT state, sdo_util.to_wkbgeometry(geometry)
        FROM TestStates""")
gdf = gpd.GeoDataFrame(cursor.fetchall(), columns = ['state', 'wkbgeometry'])

# create GeoSeries to replace the WKB geometry column
gdf['geometry'] = gpd.GeoSeries(gdf['wkbgeometry'].apply(lambda x: loads(x)))
del gdf['wkbgeometry']

# display the GeoDataFrame
print()
print(gdf)

# perform a basic GeoPandas operation (unary_union)
# to combine the 3 adjacent states into 1 geometry
print()
print("GeoPandas combining the 3 geometries into a single geometry...")
print(gdf.unary_union)

