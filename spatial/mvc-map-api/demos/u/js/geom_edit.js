/*
 Table creation scripts
 --=========================================
-- Part I: 
-- logon as dba to create a user; 
-- the db instance name may be different from what's shown below.

show con_name
show user;
alter session set container=pdb19c_2;  --pdb19c_2 on a dbhost
drop user mvtest cascade;

create user mvtest identified by mvtest;
grant create session, create view, connect, resource to mvtest;
--grant dba to mvtest;
grant unlimited tablespace to mvtest;

--======================================================
-- Part II
-- Create tables and populate table, metadata, and indexes

--  DDL for Table EDIT_LINES
--------------------------------------------------------
-- table 1 starts:

drop TABLE EDIT_LINES  purge;

CREATE TABLE EDIT_LINES
(ID    VARCHAR2(100)
,type        VARCHAR2(100)
,GEOM       MDSYS.SDO_GEOMETRY NOT NULL
);

Insert into EDIT_LINE (ID,TYPE,GEOM) values ('1','t1',MDSYS.SDO_GEOMETRY(2002, 3857, NULL, MDSYS.SDO_ELEM_INFO_ARRAY(1, 2, 1), MDSYS.SDO_ORDINATE_ARRAY(-13610729, 4513152,-13610580, 4513071)));
COMMIT;
-- TABLE 1 of 3 done!

delete user_sdo_geom_metadata
where TABLE_NAME = 'EDIT_LINES' and COLUMN_NAME = 'GEOM';
  
Insert into user_sdo_geom_metadata
(TABLE_NAME,COLUMN_NAME,DIMINFO,SRID)
 values ('EDIT_LINES','GEOM'
,MDSYS.SDO_DIM_ARRAY(
       MDSYS.SDO_DIM_ELEMENT('X', -100000, 10000, 0.005)
     , MDSYS.SDO_DIM_ELEMENT('Y', -100000, 10000, 0.005))
,'3857');

DROP INDEX EDIT_LINES_GEOM_SIDX FORCE;
CREATE INDEX EDIT_LINES_GEOM_SIDX ON EDIT_LINES(GEOM)
INDEXTYPE IS MDSYS.SPATIAL_INDEX_V2;
-- table 1 meta data done!

--===========================================
----------------------------

--------------------------------------------------------
--  DDL for Table EDIT_POINTS
--------------------------------------------------------
-- table 2 of 3 starts:

drop TABLE EDIT_POINTS  purge;

CREATE TABLE EDIT_POINTS
(ID        VARCHAR2(100)
,type      VARCHAR2(100)
,GEOM       MDSYS.SDO_GEOMETRY NOT NULL
);
REM INSERTING into EDIT_POINTS
SET DEFINE OFF;

Insert into EDIT_POINT (ID,TYPE,GEOM) values ('1','t2',MDSYS.SDO_GEOMETRY(2001, 3857, MDSYS.SDO_POINT_TYPE(-13610729, 4513152, NULL), NULL, NULL));
commit;
-- table 2 of 3 is done!
--------------------------

delete user_sdo_geom_metadata
where TABLE_NAME = 'EDIT_POINTS'
  and COLUMN_NAME = 'GEOM';
  
Insert into user_sdo_geom_metadata
(TABLE_NAME,COLUMN_NAME,DIMINFO,SRID)
 values ('EDIT_POINTS','GEOM'
,MDSYS.SDO_DIM_ARRAY(
       MDSYS.SDO_DIM_ELEMENT('X', -100000, 10000, 0.005)
     , MDSYS.SDO_DIM_ELEMENT('Y', -100000, 10000, 0.005))
,'3857');

DROP INDEX EDIT_POINTS_GEOM_SIDX FORCE;
CREATE INDEX EDIT_POINTS_GEOM_SIDX ON EDIT_POINTS(GEOM)
INDEXTYPE IS MDSYS.SPATIAL_INDEX;
-- table 2 meta data done!

--==============================================================
--------------------------------------------------------
--  DDL for Table EDIT_POLYGONS
--------------------------------------------------------
-- table 3 of 3 starts:


drop TABLE EDIT_POLYGONS  purge;

CREATE TABLE EDIT_POLYGONS
(ID        VARCHAR2(100)
,type   VARCHAR2(100)
,GEOM       MDSYS.SDO_GEOMETRY NOT NULL
);
REM INSERTING into EDIT_POLYGONS
SET DEFINE OFF;

Insert into EDIT_POLYGON (ID,TYPE,GEOM) values ('30','t1',MDSYS.SDO_GEOMETRY(2003, 3857, NULL, MDSYS.SDO_ELEM_INFO_ARRAY(1, 1003, 1), MDSYS.SDO_ORDINATE_ARRAY(-13610580, 4513071, -13610582, 4513115,  -13610536, 4513119,  -13610580, 4513071 )));
commit;
-- table 3 of 3 is done!
------------------------


delete user_sdo_geom_metadata
where TABLE_NAME = 'EDIT_POLYGONS'
  and COLUMN_NAME = 'GEOM';
  
Insert into user_sdo_geom_metadata
(TABLE_NAME,COLUMN_NAME,DIMINFO,SRID)
 values ('EDIT_POLYGONS','GEOM'
,MDSYS.SDO_DIM_ARRAY(
       MDSYS.SDO_DIM_ELEMENT('X', -100000, 10000, 0.005)
     , MDSYS.SDO_DIM_ELEMENT('Y', -100000, 10000, 0.005))
,'3857');

DROP INDEX EDIT_POLYGONS_GEOM_SIDX FORCE;
CREATE INDEX EDIT_POLYGONS_GEOM_SIDX ON EDIT_POLYGONS(GEOM)
INDEXTYPE IS MDSYS.SPATIAL_INDEX_V2;
-- table 3 meta data done!

----------------------------
--==========================



----------------------------
--==========================

-- Last step: verification:
select * from EDIT_LINES;
select * from EDIT_POINTS;
select * from EDIT_POLYGONS;

select *  from user_sdo_geom_metadata;
--desc all_indexes;
select owner, table_name, index_name from all_indexes where table_name like 'EDIT_%';


-- Part III
-- User MapBuilder to import mapviewer theme/style meta data in file: geometry_edit.dat

COMMIT;
 */
var SUB_POLYGON = 0;
      var SUB_RECTANGLE = 1;
      var SUB_CIRCLE = 2;
      var SUB_CUTOUT = 3;

      var m_oMap;
      var baseURL  = "http://"+document.location.host+"/mapviewer";

      var m_oColorStyleEdit;

      // style backup
      var m_oPointRenderStyle_backup,
          m_oPointHoverStyle_backup,
          m_oPointSelectStyle_backup;
      var m_oLineRenderStyle_backup,
          m_oLineHoverStyle_backup,
          m_oLineSelectStyle_backup;
      var m_oPolygonRenderStyle_backup,
          m_oPolygonHoverStyle_backup,
          m_oPolygonSelectStyle_backup;
  
      var m_oPointRenderStyle,
          m_oPointHoverStyle,
          m_oPointSelectStyle;
      var m_oPointEditStyle;
      var m_oLineRenderStyle,
          m_oLineHoverStyle,
          m_oLineSelectStyle;
      var m_oPolygonRenderStyle,
          m_oPolygonHoverStyle,
          m_oPolygonSelectStyle;
      //var m_oLineEditStyle;

      var m_oLayer_Line,
          m_oLayer_Point,
          m_oLayer_Polygon,
          m_oLayer_Active;
      var m_oLayer_SnapPoint;
      var layerStyle;
      var m_oMarkerSnapPointAtVertex;
      var m_oMarkerSnapPointOnSeg;
      var tool;
      var m_oSnapFeature;
      var m_iSnapTol = 5;  // pixels

      var m_iNewFeatCounter = 0;
      var m_iCurMode; // current mode: 0: select, 1: edit, or 2: draw/create      
      var m_iCurLayer; // current layer: 0: poiont, 1: linestring, or 2: polygon
      
      OM.gv.setResourcePath("../..");
      OM.gv.setHttpMethod('GET');
      OM.gv.setLogLevel("warning");  // output more logs

  
    function showMap() {
      var baseURL  = "http://"+document.location.host+"/mapviewer";
      m_oMap = new OM.Map(
      document.getElementById('map'),
      {
          mapviewerURL: baseURL
      }) ;

      var tileLayer = new OM.layer.ElocationTileLayer( "eloc", 
                                  {//"appID": "AppIDGC123456", // fake app id
                                    "layerName": "WORLD_MAP"
                                  });//  'WORLD_MAP', 'BI_WORLD_MAP', or 'BI_WORLD_MAP_LIGHT'.
      m_oMap.addLayer(tileLayer) ;

      // create vector layer needed styles
      createStyles();
      
      // create all layers and add them onto map
      addVectorLayers();
      setActiveLayer(m_oLayer_Point);  // the initial active layer is point
      m_oLayer_Point.enableFeatureSelection(true);
      m_oLayer_Line.enableFeatureSelection(false);
      m_oLayer_Polygon.enableFeatureSelection(false);
      enableSubTypes("hidden");
      setPointStyles_SelectMode();

      addListeners();

      m_oMap.setSnapTolerance(m_iSnapTol);

      m_oMap.setMapCenter(new OM.geometry.Point(-122.2640, 37.5297 ,8307) );
      m_oMap.setMapZoomLevel(15) ;
      addMapControls(m_oMap);
      m_oMap.addListener(OM.event.MapEvent.MAP_AFTER_REFRESH, backupStyles);

      m_oMap.init();
      
    let myhandler =function (evt) 
    {
      let x = m_oMap.getCursorLocation().getX().toFixed(2);
      let y = m_oMap.getCursorLocation().getY().toFixed(2);
      let z = m_oMap.getMapZoomLevel();
      document.getElementById("x").innerHTML="X: "+x;  
      document.getElementById("y").innerHTML="Y: "+y;  
      document.getElementById("z").innerHTML="Zoom level: "+z;
    }
     
      m_oMap.addListener("mouseMove", myhandler);
    }
      
      function backupStyles() {
        m_oMap.deleteListener(OM.event.MapEvent.MAP_AFTER_REFRESH, backupStyles);

        m_oPointRenderStyle_backup = m_oLayer_Point.getRenderingStyle();
        m_oLineRenderStyle_backup = m_oLayer_Line.getRenderingStyle();
        m_oPolygonRenderStyle_backup = m_oLayer_Polygon.getRenderingStyle();
      }
      
      function restoreStyles() {
        m_oMap.deleteListener(OM.event.MapEvent.MAP_AFTER_REFRESH, backupStyles);

        m_oLayer_Point.setRenderingStyle(m_oPointRenderStyle_backup);
        m_oLayer_Point.hoverStyle=null;//setHoverStyle(null);//m_oPointHoverStyle_backup);
        m_oLayer_Point.selectionStyle=null;//setSelectStyle(null);//m_oPointSelectStyle_backup);
        
        m_oLayer_Line.setRenderingStyle(m_oLineRenderStyle_backup);
        m_oLayer_Line.hoverStyle=null;//setHoverStyle(null);//m_oLineHoverStyle_backup);
        m_oLayer_Line.selectionStyle=null;//setSelectStyle(null);//m_oLineSelectStyle_backup);
        
        m_oLayer_Polygon.setRenderingStyle(m_oPolygonRenderStyle_backup);
        m_oLayer_Polygon.hoverStyle=null;//setHoverStyle(null);//m_oPolygonHoverStyle_backup);
        m_oLayer_Polygon.selectionStyle=null;//setSelectStyle(null);//m_oPolygonSelectStyle_backup);
    }

    function createStyles() {
      m_oColorStyleEdit = new OM.style.Color({fill:"#FF0000",fillOpacity:1,strokeThickness:3,stroke:"#000000"});

//      m_oPointRenderStyle = new OM.style.Color({fill:"#878c90",
//                                                fillOpacity:0.75,
//                                                strokeThickness:1,
//                                                stroke:"#ffffff"});
      var markerSize = 15;
      m_oPointRenderStyle = new OM.style.Marker({ width: markerSize, height: markerSize, 
                              vectorDef: [{ shape: { type: "circle", cx: 0, cy: 0 }, 
                                            style: { fill: "#878c90", fillOpacity: 0.75, stroke: "#ffffff", strokeThickness: 1 } }] });
      m_oPointHoverStyle = new OM.style.Marker({ width: markerSize, height: markerSize, 
                              vectorDef: [{ shape: { type: "circle", cx: 0, cy: 0 }, 
                                            style: { fill: "#85BBE7", fillOpacity: 0.75, stroke: "#ffffff", strokeThickness: 1 } }] });
      m_oPointSelectStyle = new OM.style.Marker({ width: markerSize, height: markerSize, 
                              vectorDef: [{ shape: { type: "circle", cx: 0, cy: 0 }, 
                                            style: { fill: "#027BC7", fillOpacity: 0.75, stroke: "ffffff", strokeThickness: 1 } }] });
      m_oPointEditStyle = new OM.style.Marker({ width: markerSize, height: markerSize, 
                              vectorDef: [{ shape: { type: "circle", cx: 0, cy: 0 }, 
                                            style: { fill: "#027BC7", stroke: "#ffffff", strokeThickness: 1 } }] });
      
      //m_oLineRenderStyle = new OM.style.Line({stroke:"#878c90",strokeThickness:2});
      m_oLineRenderStyle = new OM.style.Line({stroke:"#F1998B",strokeThickness:4});
      m_oLineHoverStyle = new OM.style.Line({stroke:"#85BBE7",strokeThickness:4});//, strokeDash:[6,4]});
      m_oLineSelectStyle = new OM.style.Line({stroke:"#027BC7",strokeThickness:4});
      //m_oLineEditStyle = new OM.style.Line({stroke:"#027BC7",strokeThickness:2});
      
      m_oPolygonRenderStyle = new OM.style.Color({stroke:"#ffffff",fill:"#878c90",fillOpacity:.75,strokeThickness:1});
      m_oPolygonHoverStyle = new OM.style.Color({stroke:"#85BBE7",fill:"#878c90",fillOpacity:.75,strokeThickness:2});
      m_oPolygonSelectStyle = new OM.style.Color({stroke:"#027BC7",fill:"#ffffff",fillOpacity:.75,strokeThickness:2});

      m_oMarkerSnapPointOnSeg = new OM.style.Marker({
              vectorDef:[
                { shape:{
                    type:"circle",
                    width: m_iSnapTol*4, 
                    height: m_iSnapTol*4,
                    cx: m_iSnapTol*2,
                    cy: m_iSnapTol*2
                  },
                  style:{
                    fill:"#ffffff",
                    fillOpacity:0.5,
                    stroke:"#bb0000",
                    strokeThickness:2}
                },
                { shape:{
                    type:"circle",
                    width: m_iSnapTol*2, 
                    height: m_iSnapTol*2,
                    cx: m_iSnapTol*2,
                    cy: m_iSnapTol*2
                  },
                  style:{
                    fill:"#ffffff",
                    fillOpacity:1,
                    stroke:"#bb0000",
                    strokeThickness:1}
                }
              ]
            });

            
      m_oMarkerSnapPointAtVertex = new OM.style.Marker({
              vectorDef:[
                { shape:{
                    type:"circle",
                    width: m_iSnapTol*4, 
                    height: m_iSnapTol*4,
                    cx: m_iSnapTol*2,
                    cy: m_iSnapTol*2
                  },
                  style:{
                    fill:"#ffffff",
                    fillOpacity:0.5,
                    stroke:"#00bb00",
                    strokeThickness:2}
                },
                { shape:{
                    type:"circle",
                    width: m_iSnapTol*2, 
                    height: m_iSnapTol*2,
                    cx: m_iSnapTol*2,
                    cy: m_iSnapTol*2
                  },
                  style:{
                    fill:"#ffffff",
                    fillOpacity:1,
                    stroke:"#00bb00",
                    strokeThickness:1}
                }
              ]
            });
  }
      
    function addListeners() {
      m_oLayer_Active.addListener(OM.event.MouseEvent.MOUSE_CLICK, featureClicked); 
      m_oLayer_Active.addListener(OM.event.LayerEvent.FEATURE_SELECTED, featureSelected);
      m_oLayer_Active.addListener(OM.event.LayerEvent.FEATURE_DESELECTED, featureDeselected);
    }
    function removeListenersAndDeselect() {
      m_oLayer_Active.clearSelectedFeatures(); 
      
      m_oLayer_Active.deleteListener(OM.event.MouseEvent.MOUSE_CLICK, featureClicked); 
      m_oLayer_Active.deleteListener(OM.event.LayerEvent.FEATURE_SELECTED, featureSelected);
      m_oLayer_Active.deleteListener(OM.event.LayerEvent.FEATURE_DESELECTED, featureDeselected);
    }
    
    function setActiveLayer(layer) {
      m_oLayer_Active = layer;
    }
    
    function featureMoving(fmv) {
    // here target can be the feature itself or feature shape or 'possible point'.
      var feature = fmv.target;
      if(OM.notNull(feature.parentFeature)) { // moving feature's vertex: line/polygon
        if(OM.notNull(m_oSnapFeature)) {
          m_oLayer_SnapPoint.removeFeature(m_oSnapFeature);
          m_oLayer_SnapPoint.redraw();
          m_oSnapFeature = null;
        }

        feature.parentFeature.pointToSnap = null;

        var pntObj = getLayerSnapPoint(feature.parentFeature);  //the feature under editing
        if(OM.notNull(pntObj)) {
          var snapPoint = pntObj.point;
          var location = pntObj.location;

          feature.parentFeature.pointToSnap = []; 
          feature.parentFeature.pointToSnap.push(snapPoint.getX()); // in data units
          feature.parentFeature.pointToSnap.push(snapPoint.getY()); // in data units 

          // update snap Feature to display
          if (location ===2) {  // on segment
          m_oSnapFeature = new OM.Feature("SnapPoint",snapPoint);
            m_oLayer_SnapPoint.setRenderingStyle(m_oMarkerSnapPointOnSeg);
          } else {  // at start or ending point
            m_oSnapFeature = new OM.Feature("SnapPoint",snapPoint);
            m_oLayer_SnapPoint.setRenderingStyle(m_oMarkerSnapPointAtVertex);
          }
          m_oLayer_SnapPoint.addFeature(m_oSnapFeature);
          m_oLayer_SnapPoint.redraw();
        }                  
      } else if (feature.geo && feature.geo.type === "Point") { //moving a point marger
        if(OM.notNull(m_oSnapFeature)) {
          m_oLayer_SnapPoint.removeFeature(m_oSnapFeature);
          m_oLayer_SnapPoint.redraw();
          m_oSnapFeature = null;
        }

        feature.pointToSnap = null;

        var pntObj = getLayerSnapPoint();  // application can define a snap vector layer 
        if(OM.notNull(pntObj)) {
          var snapPoint = pntObj.point;
          var location = pntObj.location;

          feature.pointToSnap = []; 
          feature.pointToSnap.push(snapPoint.getX()); // in data units
          feature.pointToSnap.push(snapPoint.getY()); // in data units 

          // update snap Feature to display
          if (location ===2) {  // on segment
          m_oSnapFeature = new OM.Feature("SnapPoint",snapPoint);
            m_oLayer_SnapPoint.setRenderingStyle(m_oMarkerSnapPointOnSeg);
          } else {  // at start or ending point
            m_oSnapFeature = new OM.Feature("SnapPoint",snapPoint);
            m_oLayer_SnapPoint.setRenderingStyle(m_oMarkerSnapPointAtVertex);
          }
          m_oLayer_SnapPoint.addFeature(m_oSnapFeature);
          m_oLayer_SnapPoint.redraw();
        }
      } else { // moving whole feature with snapping - (not supported yet).
        // here we can use a specific snap point defined for feature, and then when moving check
        // if this snap point match any other snap layer point. 
      }
    }
    
    function featureMoved() {
        if(OM.notNull(m_oSnapFeature))
        {
          m_oLayer_SnapPoint.removeFeature(m_oSnapFeature);
          m_oLayer_SnapPoint.redraw();
          m_oSnapFeature = null;
        }             
    }
    
    function featureDeselected(ctx) {
            var deselectedFeature = ctx.deselectedFeature;
            deselectedFeature.deleteListeners(OM.event.LayerEvent.FEATURE_MOVING);
            deselectedFeature.deleteListeners(OM.event.LayerEvent.FEATURE_MOVED);
    }
    function featureSelected(ctx) {
          var selFeature = ctx.selectedFeature;

          // to track when feature is being moved
          if(!(selFeature.hasListener(OM.event.LayerEvent.FEATURE_MOVING, featureMoving))) {
            selFeature.addListener(OM.event.LayerEvent.FEATURE_MOVING, featureMoving);
          }

          // to track when feature is moved
          if(!(selFeature.hasListener(OM.event.LayerEvent.FEATURE_MOVED, featureMoved))) {
            selFeature.addListener(OM.event.LayerEvent.FEATURE_MOVED, featureMoved);
          }
          // to track when feature is moved
          if(!(selFeature.hasListener(OM.event.LayerEvent.FEATURE_DESELECTED, featureDeselected))) {
            selFeature.addListener(OM.event.LayerEvent.FEATURE_DESELECTED, featureDeselected);
          }
    }
    function addVectorLayers() {
            m_oLayer_Point = new OM.layer.VectorLayer("Point_EDIT_POINTS",
                        {def: {type: OM.layer.VectorLayer.TYPE_PREDEFINED,
                                               dataSource: "mvtest",
                                               theme: "EDIT_POINTS",
                                               url: baseURL
                              },
//                        boundingTheme: true
                      });
            m_oLayer_Line = new OM.layer.VectorLayer("EDIT_LINES",
                        {def: {type: OM.layer.VectorLayer.TYPE_PREDEFINED,
                              dataSource: "mvtest",
                              theme: "EDIT_LINES",
                              url: baseURL
                              },
//                        boundingTheme: true
                      });
            m_oLayer_Polygon = new OM.layer.VectorLayer("EDIT_POLYGONS",
                        {def: {type: OM.layer.VectorLayer.TYPE_PREDEFINED,
                              dataSource: "mvtest",
                              theme: "EDIT_POLYGONS",
                              url: baseURL
                              },
//                        boundingTheme: true
                      });
                      
          m_oLayer_Line.enableEditingContextMenu(true);
          m_oLayer_Polygon.enableEditingContextMenu(true);
          
          m_oLayer_SnapPoint = new OM.layer.VectorLayer(
            "snap_layer", {
              def : {
                type : OM.layer.VectorLayer.TYPE_LOCAL
              }
            });
          
        m_oLayer_Polygon.enableInfoWindow(false);
        m_oLayer_Line.enableInfoWindow(false);
        m_oLayer_Point.enableInfoWindow(false);
        m_oMap.addLayer(m_oLayer_Polygon);
        //m_oLayer_Polygon.setHideEditCircleVertices(false); // test this method/option
        m_oMap.addLayer(m_oLayer_Line);
        m_oMap.addLayer(m_oLayer_Point);
        m_oMap.addLayer(m_oLayer_SnapPoint);
      }
      function setStylesAndMode() {
        restoreStyles();
        
        var mode = getCheckedMode();
        var n = getCheckedLayer();
        switch (mode) {
          case 0:  // select mode
            if (n===0) { // point
              setPointStyles_SelectMode();
            } else if(n===1) {
              setLineStyles_SelectMode();
            } else if(n===2) {
              setPolygonStyles_SelectMode();
            }
            break;
          case 1:  // edit mode
            if (n===0) {
              setPointStyles_EditMode();
            } else if (n===1) {
              setLineStyles_EditMode();
            } else if (n===2) {
              setPolygonStyles_EditMode();
            }
            m_oLayer_Active.enableFeatureEditing(true);
            break;
          case 2: // draw mode
            if (n===0) {
              setPointStyles_DrawMode();
            } else if (n===1){
              setLineStyles_DrawMode();
            } else if (n===2){
              setPolygonStyles_DrawMode();
            }
            startNewDrawing();
            break;
        }
        updateLayerEnableSelectionSetting();
        // keep track of current mode
        // mode change between edit <---> draw does not require a save() operation
        m_iCurMode = mode; 
        m_iCurLayer = n; 

      }

      function selectLayerPoint() {
        if (m_iCurLayer === 0) {
          return;
        }
        saveOrDiscardChanges();
        removeListenersAndDeselect();
        setActiveLayer(m_oLayer_Point);  
        addListeners();
        
        setStylesAndMode();
      }
      
      // radio checked handler
      function selectLayerLine() {
        if ( m_iCurLayer === 1) {
          return;
        }
        saveOrDiscardChanges();
        removeListenersAndDeselect();
        setActiveLayer(m_oLayer_Line);  
        addListeners();
        
        setStylesAndMode();
      }
      
      function selectLayerPolygon() {
        if (m_iCurLayer === 2) {
          return;
        }
        saveOrDiscardChanges();
        removeListenersAndDeselect();
        setActiveLayer(m_oLayer_Polygon);
        addListeners();
        setStylesAndMode();
      }
      //0: point; 1: line; 2: polygon
      function getCheckedLayer() {
        var layerPoint = document.getElementById("pointlayer");
        var layerLine = document.getElementById("linelayer");
        var layerPolygon = document.getElementById("polygonlayer");
        if (layerPoint.checked) {
          return 0;
        } else if (layerLine.checked) {
          return 1;
        } else if (layerPolygon.checked) {
          return 2;
        }
      }

      //0: point; 1: line; 2: polygon
      function getCheckedSnapLayer() {
        var layerPoint = document.getElementById("snapToPoint");
        var layerLine = document.getElementById("snapToLine");
        var layerPolygon = document.getElementById("snapToPolyggon");
        if (layerPoint.checked) {
          return 0;
        } else if (layerLine.checked) {
          return 1;
        } else if (layerPolygon.checked) {
          return 2;
        }
      }

      //0: point; 1: line; 2: polygon
      function getCheckedMode() {
        var disp = document.getElementById("display");
        var edit = document.getElementById("edit");
        var draw = document.getElementById("draw");
        if (disp.checked) {
          return 0;
        } else if (edit.checked) {
          return 1;
        } else if (draw.checked) {
          return 2;
        }
      }

      function modeSelect() {
        if (m_iCurMode === 0) {
          return;
        }
        saveOrDiscardChanges();
        removeTool();
        setStylesAndMode();

        m_oLayer_Active.enableFeatureEditing(false);
          
        updateSubtypeComboBox();
        buildAttributeTable();
      }

      function modeEdit() {
        if (m_iCurMode === 1) {
          return;
        }
        if (m_iCurMode === 0) {
          saveOrDiscardChanges();
        }
        removeTool();
        setStylesAndMode();

        m_oLayer_Active.enableFeatureEditing(true);  // this line maybe no need.
          
        enableEditingOrDrawing();
        
        updateSubtypeComboBox();
        buildAttributeTable();
      }

      // radio handler
      function modeDraw() {
        if (m_iCurMode === 2) {
          return;
        }
        if (m_iCurMode === 0) {
          saveOrDiscardChanges();
        }
        setStylesAndMode();        
        //startNewDrawing(); the function above has a call.
        updateSubtypeComboBox();        
     }
     
     function undo()
     {
        var iMode = getCheckedMode();
        if (iMode === 0) { //if in select mode
          return;
        }

        if(tool && tool instanceof OM.tool.RedlineTool && !(tool instanceof OM.tool.BreakLineTool) &&
          tool.status === OM.tool.Tool.STARTED) {    
         m_oMap.getUndoManager().undo();
        } else {
          m_oLayer_Active.getUndoManager().undo();
        }
      }

      function redo()
      {
        var iMode = getCheckedMode();
        if (iMode === 0) { //if in select mode
          return;
        }

        if(tool && tool instanceof OM.tool.RedlineTool && !(tool instanceof OM.tool.BreakLineTool) &&
           tool.status === OM.tool.Tool.STARTED) {
          m_oMap.getUndoManager().redo();
        } else {
          m_oLayer_Active.getUndoManager().redo();
        }
      }

      function duplicate()
      {
        var iMode = getCheckedMode();
        if (iMode === 0) { //if in display mode
          return;
        }
        
        var feats = m_oLayer_Active.getSelectedFeatures();
        if(OM.isNull(feats) || feats.length !== 1) {
          console.log("Select one feature first for duplication");
          return;
        }

        if(tool && !(tool instanceof OM.tool.DuplicateTool)) {
          removeTool();
        }
               
         if (!tool) {
            tool = new OM.tool.DuplicateTool(m_oMap, feats[0]);           
            tool.start();
         }
         
        tool.addListener(OM.event.ToolEvent.TOOL_END, function(ctx) {
                          removeTool();
                        });
      }

      function breakline()
      {
        var iMode = getCheckedMode();
        if (iMode === 0) { //if in display mode
          return;
        }
        
        var feats = m_oLayer_Active.getSelectedFeatures();
        if(OM.isNull(feats) || feats.length !== 1 || 
           (feats[0].geo.type !== "LineString"&& feats[0].geo.type !== "MultiLineString")
                 ) {
          console.log("Select one linestring or multi-linestring feature first to break a segment into two pieces.");
          return;
        }

        if(tool && !(tool instanceof OM.tool.BreakLineTool)) {
          removeTool();
        }
               
         if (!tool) {
            tool = new OM.tool.BreakLineTool(m_oMap, feats[0]);           
            tool.start();
         }
         
        tool.addListener(OM.event.ToolEvent.TOOL_END, function(ctx) {
                          removeTool();
                        });
      }

      // this is to ge the result back from saveEditing method (result witll contain true or false)
      function saveCallBack(result) {
        if(OM.notNull(result)) {
          if ( result ) {
            document.getElementById("SaveResponse").innerHTML="Success!";
          } else {
            document.getElementById("SaveResponse").innerHTML="Failed to save.";
          }
        } else {
          document.getElementById("SaveResponse").innerHTML="Failed to get server response.";
        }
        setTimeout(clearSaveStatus,3000);
      }   
     
    function setPointStyles_SelectMode() {
      m_oLayer_Point.setStyles(
              {//render: m_oPointRenderStyle,
               hover:  m_oPointHoverStyle,
               select: m_oPointSelectStyle,
               edit:   m_oPointEditStyle
              });
    }
    function setLineStyles_SelectMode() {
      
      m_oLayer_Line.setStyles(
              {//render: m_oLineRenderStyle,
               hover: m_oLineHoverStyle,
               select: m_oLineSelectStyle,
               //edit: m_oLineEditStyle
              });
    }

    function setPolygonStyles_SelectMode() {
      m_oLayer_Polygon.setStyles(
              {//render: m_oPolygonRenderStyle,
               hover:  m_oPolygonHoverStyle,
               select: m_oPolygonSelectStyle,
              });
    }
    function setPointStyles_EditMode() {
      m_oLayer_Point.setStyles(
              {render: m_oPointRenderStyle,
               hover:  m_oPointHoverStyle,
               select: m_oPointSelectStyle,
               edit_point: m_oPointEditStyle
              });
    }
    function setLineStyles_EditMode() {
      m_oLayer_Line.setStyles(
              {render: m_oLineRenderStyle,
               hover: m_oLineHoverStyle,
               select: m_oLineSelectStyle
              });
    }

    function setPolygonStyles_EditMode() {
      m_oLayer_Polygon.setStyles(
              {render: m_oPolygonRenderStyle,
               hover:  m_oPolygonHoverStyle,
               select: m_oPolygonSelectStyle
              });
    }
    
    function setMode(id) {
      if (id === 'select') {
        m_iCurMode = 0;
      } else if (id === 'edit') {
        m_iCurMode = 1;
      } else if (id === 'draw') {
        m_iCurMode = 2;
      } else {
        console.log ("invalid mode");
      }
      document.getElementById(id).checked = true;      
    }
    
    function setPointStyles_DrawMode() {
      m_oLayer_Point.setStyles(
              {render: m_oPointRenderStyle,
               hover:  m_oPointHoverStyle,
               select: m_oPointSelectStyle
              });
    }
    function setLineStyles_DrawMode() {
      m_oLayer_Line.setStyles(
              {render: m_oLineRenderStyle,
               hover: m_oLineHoverStyle,
               select: m_oLineSelectStyle
              });
    }

    function setPolygonStyles_DrawMode() 
    {
      m_oLayer_Polygon.setStyles(
              {render: m_oPolygonRenderStyle,
               hover:  m_oPolygonHoverStyle,
               select: m_oPolygonSelectStyle,
              });
    }
    
    /** 
     * for creating a new feature
     * @returns {undefined}
     */
    function startNewDrawing() {        
        removeTool();
        enableEditingOrDrawing();
        
        var nType = getCheckedLayer(); 
        if (!tool) {
           // rectangle tool does not have snap-to 
            if (nType === 2) {  // polygon
              var subType = getSubType();
              if (OM.isNull(subType)) {
                subType = 0;
              }
              if (subType===SUB_POLYGON) {  // polygon
                tool = new OM.tool.RedlineTool(m_oMap, OM.tool.RedlineTool.TYPE_POLYGON);
              } else if (subType === SUB_RECTANGLE) {
                tool = new OM.tool.RectangleTool(m_oMap);
                //tool.setZeroSizeAllowed(true);
              } else if (subType === SUB_CIRCLE) {
                tool = new OM.tool.CircleTool(m_oMap);
                //tool.setZeroSizeAllowed(true);
              } else if (subType === SUB_CUTOUT) { // cutout
                var feats = m_oLayer_Active.getSelectedFeatures();
                if(OM.isNull(feats) || feats.length !== 1) {
                  alert("Select a polygon feature first before adding a void into...");
                  setMode("edit");
                  return;
                  // enter a one time selection mode                  
                }

                newVoidPolygon();
              }
              setPolygonStyles_DrawMode();
            }
            else if(nType === 1) {
              tool = new OM.tool.RedlineTool(m_oMap, OM.tool.RedlineTool.TYPE_LINESTRING);
              setLineStyles_DrawMode();
            }
            else if(nType === 0) {
              tool = new OM.tool.RedlineTool(m_oMap, OM.tool.RedlineTool.TYPE_POINT);
              setPointStyles_DrawMode();
            }
            tool.addListener(OM.event.ToolEvent.SNAP_POINT, startNewDrawingSnapListener);

            tool.addListener(OM.event.ToolEvent.TOOL_END, onToolComplete);
            tool.start();
         }
     }
     
     function startNewDrawingSnapListener()
     {
        if(OM.notNull(m_oSnapFeature)) {
          m_oLayer_SnapPoint.removeFeature(m_oSnapFeature);
          m_oLayer_SnapPoint.redraw();
          m_oSnapFeature = null;
        }

        tool.snapPoint = null; //[]; 

        var pntObj = getLayerSnapPoint();  // application can define a vector of snap layers and check all. 
        if(OM.notNull(pntObj)) {
          var snapPoint = pntObj.point;
          var location = pntObj.location;
          var screenLoc = m_oMap.getScreenLocation(snapPoint);
          tool.snapPoint = []; 
          tool.snapPoint.push(screenLoc.x);  // in screen units
          tool.snapPoint.push(screenLoc.y);  // in screen units;

          m_oSnapFeature = new OM.Feature("SnapPoint",snapPoint);
          if (location ===2) {
            m_oLayer_SnapPoint.setRenderingStyle(m_oMarkerSnapPointOnSeg);
          } else {
            m_oLayer_SnapPoint.setRenderingStyle(m_oMarkerSnapPointAtVertex);
          }

          m_oLayer_SnapPoint.addFeature(m_oSnapFeature);
          m_oLayer_SnapPoint.redraw();                  
        }
      }
     
      function generateId() {
        var currentDate = new Date();
        var date = currentDate.getDate();
        var month = currentDate.getMonth(); 
        var year = currentDate.getFullYear();
        var timestamp = Math.trunc(currentDate.getTime()/1000); //seconds from 1970
        var nLayer = getCheckedLayer();
        var sLayer = nLayer===0 ? "point": (nLayer===1?"line":"polygon");

        var id= sLayer+"_"+year+"_"+(month+1)+"_"+date+"_"+(m_iNewFeatCounter++)+"_"+timestamp;
        return id;
    }
    
    function retrieveToolGeometry() {
      var geom;
      var oFeatureGeometry = tool.getGeometry();
      if (tool instanceof OM.tool.RectangleTool) {
          var nXMin = oFeatureGeometry.coordinates[0];
          var nYMin = oFeatureGeometry.coordinates[1];
          var nXMax = oFeatureGeometry.coordinates[2];
          var nYMax = oFeatureGeometry.coordinates[3];
          var sSRID = m_oMap.getMapContext().getUniverse().getSRID();
          //always draw the rectangle as a polygon with four axis-aligned vertices
          oFeatureGeometry = new OM.geometry.Polygon([[nXMin, nYMin, nXMax, nYMin, nXMax, nYMax, nXMin, nYMax, nXMin, nYMin]], sSRID);

          geom = new OM.geometry.Polygon([[nXMin, nYMin, nXMax, nYMin, nXMax, nYMax, nXMin, nYMax, nXMin, nYMin]], sSRID);
        } else if (tool instanceof OM.tool.CircleTool) {
          geom = tool.getGeometry();
          if (OM.notNull(geom)) {
            geom = geom.circlePolygon;
          }
      } else if(tool._geoType === 3) {
        // should be counterclockwise (for SPATIAl)
        geom = tool.getGeometry();
        var ords = geom.getOrdinates()[0];
        var polyCW = OM.util.GeomUtil.isClockwise(ords);

        if (polyCW) {
            ords = OM.util.GeomUtil.reverseCoordinates(ords);
            geom.coordinates[0] = ords;
        }
      } else {
        geom = tool.getGeometry();
      }
      return geom;
    }

    function onToolComplete( ) {
      tool.deleteListener(OM.event.ToolEvent.TOOL_END, onToolComplete);
      if(OM.isNull(tool._geometry)){
        startNewDrawing();  // allow to start to draw a new circle
        return;
      }
      if (tool instanceof OM.tool.VoidPolygonTool) {
        setMode("edit");
        return;
      }
      
      var geom = retrieveToolGeometry();
      // set the inital attribute values to make the display work properly
      var attr = {};  // this section did not seem to work as espected, can be delt later.
      if (geom.type === "Point" ){
        attr["TYPE"] = 't1';  // fix it in demo
      } else if (geom.type === "LineString"){
         attr["TYPE"] = "t1";// fix it in demo                   
      } else if (geom.type === "Polygon" ){
         attr["TYPE"] = "t1";// fix it in demo                   
      }

      if(OM.notNull(m_oSnapFeature))
      {
        m_oLayer_SnapPoint.removeFeature(m_oSnapFeature);
        m_oLayer_SnapPoint.redraw();
        m_oSnapFeature = null;
      }

      tool.snapPoint = null;
      tool.clear();
      tool = null;//undefined;

      // keep digitizing the next feature
      var feature = new OM.Feature(generateId(),geom, {"attributes": attr}); // tool._geometry);

      var ec = m_oLayer_Active.changeManager.addFeature(feature.id,feature);
      if(OM.notNull(ec))
      {
        m_oLayer_Active.getUndoManager().addEdit(
              {
                  changeManager: m_oLayer_Active.changeManager,
                  editChangeEvent: ec,
                  canUndo : function() { return true; },
                  canRedo : function() { return true; },
                  getPresentationName : function()
                  {
                      return "feature added";
                  },
                  undo : function()
                  {
                      this.changeManager.undo(this.editChangeEvent);
                  },
                  redo : function()
                  {
                      this.changeManager.redo(this.editChangeEvent);
                  }   
              });
            }
        startNewDrawing();  // allow to start to draw a new circle
    }
    
    function setLayerSharedBoundary()
    {
        var cbox = document.getElementById("sharedCheckBox");
        if(cbox.checked)
          m_oLayer_Active.setSharedBoundary(true);
        else
          m_oLayer_Active.setSharedBoundary(false);
    }
     
    function buildAttributeTable()
    {
      var table = document.getElementById("attrTable");
      clearAttributeTable();
      var rowCount = 1;
      var keyCol = m_oLayer_Active.keyColumn;
      if(OM.notNull(keyCol))
      {
        addTableRecord(table,rowCount,keyCol,"",true);
        rowCount = 2;
      }
      var attributes = m_oLayer_Active.getAttributeNames();
      if(OM.notNull(attributes))
      {
        for(var j=0;j < attributes.length;j++)
        {
          if(attributes[j] === keyCol)
            continue;
            
          addTableRecord(table,rowCount,attributes[j],"",false);
          rowCount = rowCount + 1;
        }        
      }
    }
    
    function addTableRecord(table,rowCount,name,value,readOnly)
    {
        var row = table.insertRow(rowCount);
        var cell1 = row.insertCell(0);
        var element1 = document.createElement("input");
        //var element1 = document.createElement("label");
        element1.type = "text";
        element1.outline = 'none';
        element1.value = name;
        element1.readOnly = true;  // editable
        //element1.innerHTML = name;
        element1.style.width = "30%";
        cell1.appendChild(element1);
          
        var cell2 = row.insertCell(1);
        var element2 = document.createElement("input");
        element2.type = "text";
        element2.value = value;
        element2.readOnly = false;
        element1.style.width = "70%";
        cell2.appendChild(element2);
        rowCount = rowCount + 1;      
    }
    
    function clearAttributeTable()
    {
      var table = document.getElementById("attrTable");
      for(var i = table.rows.length; i > 1;i--)
      {
         table.deleteRow(i -1);
      }
    }

    function featureClicked()
    {
      refreshSelectedFeatureAttributes();
    }
    
    function refreshSelectedFeatureAttributes()
    {
      clearAttributeTable();
      
      var feats = m_oLayer_Active.getSelectedFeatures();
      if(OM.isNull(feats) || feats.length === 0)
        return;
      
      var feature = feats[0];
      var rowCount = 1;
      var keyCol = m_oLayer_Active.keyColumn;
      var table = document.getElementById("attrTable");
      if(OM.notNull(keyCol))
      {
        addTableRecord(table,rowCount,keyCol,feature.id,true);
        rowCount = 2;
      }
      var attributes = m_oLayer_Active.getAttributeNames();
      if(OM.notNull(attributes)) {
        for(var j=0;j < attributes.length;j++) {
          if(attributes[j] === keyCol)
            continue;
          addTableRecord(table,rowCount,attributes[j],feature.getAttributeValue(attributes[j]),false);
          rowCount = rowCount + 1;
        }        
      }      
    }
    
    function updateFeatureAttributes()
    {
      var feats = m_oLayer_Active.getSelectedFeatures();
      if(OM.isNull(feats) || feats.length === 0)
        return;

      var keyCol = m_oLayer_Active.keyColumn;  
      var table = document.getElementById("attrTable");    
      var feature = feats[0];      
      var attrChanges = {};
      var n = table.rows.length;
      for (var r = 1; r < n; r++) {
        var attrName = table.rows[r].cells[0].childNodes[0].value;
        if(attrName === keyCol)
          continue;
        
        var attrValue = table.rows[r].cells[1].childNodes[0].value;     
        var currentValue = feature.getAttributeValue(attrName);
        if(attrValue === currentValue || (currentValue === null && attrValue.length === 0))
          continue;
        
        var attrType = m_oLayer_Active.getAttributeType(attrName); 
        if(attrType !== "string")
        {
          // validate number first
          var notNumber = isNaN(attrValue);
          if(notNumber === true || attrValue.length === 0)
            continue;
        }
        
        attrChanges[attrName] = attrValue;
      }
      
      // if has changes add to change manager
      var size = 0, key;
      for (key in attrChanges) 
      {
          if (attrChanges.hasOwnProperty(key)) 
            size++;
      }
      
      if(size > 0) {
        var eee = OM.edit.EditChangeEvent;
        var ec = m_oLayer_Active.changeManager.updateFeature(feature.id,
                                                              feature,
                                                              attrChanges,
                                                              eee.ATTRIBUTE_UPDATE);
        if(OM.notNull(ec))
        {
          m_oLayer_Active.getUndoManager().addEdit(
          {
              changeManager: m_oLayer_Active.changeManager,
              editChangeEvent: ec,
              canUndo : function() { return true; },
              canRedo : function() { return true; },
              getPresentationName : function(){
                  return "feature attributes updated";
              },
              undo : function() {
                  this.changeManager.undo(this.editChangeEvent);
                  refreshSelectedFeatureAttributes();
              },
              redo : function() {
                  this.changeManager.redo(this.editChangeEvent);
                  refreshSelectedFeatureAttributes();
              }   
          });
        }
      }
    }
    
    /**
     * 
     * @param {Object} activeFeature The feature that under editing, null of a new feature to be created
     * @returns {Object} The object contains snap info
     */
    function getLayerSnapPoint(activeFeature)
    {
        var layerToSnap;
        var nSnapLayer = getCheckedSnapLayer(); // 0,1,2
        if (nSnapLayer === 0) {
          layerToSnap = m_oLayer_Point;
        } else if (nSnapLayer === 1) {
          layerToSnap = m_oLayer_Line;
        } else if (nSnapLayer === 2) {
          layerToSnap = m_oLayer_Polygon;
        } 
        
        var point = m_oMap.getScreenPointLocation(m_oMap.mLocX, m_oMap.mLocY);
        var ptGeom = null;
        if(OM.isNull(point)) {
          return null;
        }

        // search features
        var searchPT = [point.coordinates[0],point.coordinates[1]];
        var opt;
        if (activeFeature) {
          opt = {"excludeFeature":activeFeature};  // this feature will be excluded, when provided, to search for 
                                                   // snap points. Use case: the active feature exclude itself for snapping to
        }
        
        var segPT = OM.edit.GeometrySegmentUtil.getLayerSnapPoint(layerToSnap, searchPT, opt);
        if(OM.isNull(segPT)) {
          return null;
        }
        var ptSeg = segPT.getPoint();
        ptGeom = new OM.geometry.Point(ptSeg[0],ptSeg[1],point.getSRID());
      
        return {point: ptGeom, location: segPT.pointLocation}; // 0: at start, 1:at end; 2: on seg--> in the middle of seg
    }


    function addMapControls(map) {
        addMapNavControl(map)
        addMapCopyright(map);
        addMapTitle(map);
        addMapScale(map);
        addToolBar(map);
    }
    
    
    function addMapTitle(map) {
      var maptitle = new OM.control.MapDecoration(null,
          { 
              anchorPosition: 2,
              title:"  Feature Creation and Editing",
              draggable:true, collapsible: false, 
           titleStyle:{ "font-size":"22px",
                         "font-weight":"bold",
                         "font-family":'Arial',
                         "color":"#0000d0",
                         "backgroundColor":"#FfFfFf",
                         "opacity":"0.75"                          
                        }
          });
        map.addMapDecoration(maptitle);
    }    
        
    function addMapScale(map) {
        //defines the basic properties for the map scale bars
        var sbConfig = {
            format: "BOTH",  // imperial and metric units
            anchorPosition: 5
        };

        //creates the actual sacle bar instance and sets the display style
        var scaleBar = new OM.control.ScaleBar(sbConfig);

        //defines the display style of the scale bars
        var sbStyle = {
            barThickness:4,           // default is 3
            scaleBarColor: '#0000d0',  // default is black
            fontColor: '#0000d0'  // default is black
        };
        scaleBar.setStyle(sbStyle);
        
        
        //adds the scale bar to the map decoration
        map.addMapDecoration(scaleBar); 
    }   
    
    function addMapNavControl(map) {
        var options = {
          anchorPosition: 1,
          style: OM.control.NavigationPanelBar.STYLE_PAN_AND_ZOOM_BUTTONS
                        //STYLE_FULL
                        //STYLE_ZOOM_ONLY
                        //STYLE_ZOOM_BUTTONS_ONLY  //--default value
                        //STYLE_PAN_ONLY
                        //STYLE_PAN_AND_ZOOM_BUTTONS                           
        };

        var navigationPanelBar = new OM.control.NavigationPanelBar(options);
            navigationPanelBar.setZoomLevelInfoTips({
              2: "Country",
              5: "State",
              7: "City",
              15: "Street"
            });
        map.addMapDecoration(navigationPanelBar);    
    }
    
    function addMapLayerControl(map) {
        var layerControl=new OM.control.LayerControl({
            anchorPosition:1,
            minWidth:200,
            maxHeight:400,
            left:20,
            top:20,
            font_size:14,
            font_family:"arial"  
        });
        map.addMapDecoration(layerControl);
    }
    
    function addMapCopyright(map) {    
        var mapCopyRight = new OM.control.CopyRight({anchorPosition:4,
                                                     textValue:'©2020 Oracle AskTom Map API demos ',
                                                     fontSize:11,fontFamily:'Arial',fontColor:'black'});
        map.addMapDecoration(mapCopyRight);
    }
    function addToolBar(map) {    
        var toolbar = new OM.control.ToolBar("toolbar1", 
          {
            builtInButtons : [OM.control.ToolBar.BUILTIN_ALL]
          });
        toolbar.setPosition(0.8,0.0);
        map.addToolBar(toolbar);
    }
    
    function enableSubTypes(str) {
      if (str ==='visible') {
        document.getElementById("sub_polygonTypes").style.visibility = 'visible';
      } else {
        document.getElementById("sub_polygonTypes").style.visibility = 'hidden';
      }
    }
    
    function enableEditingOrDrawing() {
        var n = getCheckedLayer();
        if (n===0) {
          setActiveLayer(m_oLayer_Point);
        } else if (n===1) {
          setActiveLayer(m_oLayer_Line);
        } else if (n===2) {
          setActiveLayer(m_oLayer_Polygon);
        }

        m_oLayer_Active.enableFeatureEditing(true);
        
        buildAttributeTable();
      }
    
      function updateSubtypeComboBox() 
      {
        var iLayer = getCheckedLayer();
        var iMode = getCheckedMode();
        if (iLayer ===2 && iMode==2) {
          enableSubTypes('visible');
        } else {
          enableSubTypes('hidden');
        }        
      }
      
      function updateLayerEnableSelectionSetting() 
      {
        m_oLayer_Point.enableFeatureSelection(false);
        m_oLayer_Line.enableFeatureSelection(false);
        m_oLayer_Polygon.enableFeatureSelection(false);
        
        var iLayer = getCheckedLayer();
        var iMode = getCheckedMode();
        if (iLayer===0) { //-- point
          if (iMode===0) {  // select
            m_oLayer_Point.enableFeatureSelection(true);
          } else if (iMode===1) { // edit
            m_oLayer_Point.enableFeatureEditing(true);
          } else if (iMode===2) { // add
            m_oLayer_Point.enableFeatureEditing(true);
          }
        } else if (iLayer===1) {  //-- line
          m_oLayer_Line.enableFeatureSelection(true);
          if (iMode===0) {  // select
            m_oLayer_Line.enableFeatureSelection(true);
          } else if (iMode===1) { // edit
            m_oLayer_Line.enableFeatureEditing(true);
          } else if (iMode===2) {
            m_oLayer_Line.enableFeatureEditing(true);
          }
        } else if (iLayer===2) {  //-- polygon
          m_oLayer_Polygon.enableFeatureSelection(true);
          if (iMode===0) {      // select
            m_oLayer_Polygon.enableFeatureSelection(true);
          } else if (iMode===1) { // edit
            m_oLayer_Polygon.enableFeatureEditing(true);
          } else if (iMode===2) {  // draw
            m_oLayer_Polygon.enableFeatureEditing(true);
          }
        }
        
        buildAttributeTable();
        updateSubtypeComboBox();
      }
      /**
       * @returns {undefined}
       */
      function removeTool() {
        if(OM.notNull(tool)) {
          tool.clear();
          tool = null;
        }        
      }
      
      function getSubType() 
      {
        var sel = document.getElementById("subTypes");
        var val = sel.value;
        if (val === "polygon") {
          return SUB_POLYGON;
        }
        if (val === "rectangle") {
          return SUB_RECTANGLE;
        }
        if (val === "circle") {
          return SUB_CIRCLE;
        }
        if (val === "cutout") {
          return SUB_CUTOUT;
        }
        return null; //"circle" (not implemented yet)
      }
      
      function onSubTypeChange() {
          startNewDrawing(); // delegate it to this line
      }
      
     function newVoidPolygon()
     {
        if(tool && !(tool instanceof OM.tool.VoidPolygonTool)) {
          removeTool();
        }
               
        if (!tool) {
          var feats = m_oLayer_Active.getSelectedFeatures();
          if (feats.length !== 1) {
            console.log("Must have one polygon selected.");
            return;
          }
          tool = new OM.tool.VoidPolygonTool(m_oMap, feats[0]);
          if(OM.isNull(tool.polygonFeature)) {
            removeTool();
            return;
          }

          //tool.start();  // should be commented 
       }
    }

    function deleteFeature()
    {
        var feats = m_oLayer_Active.getSelectedFeatures();
        for (var i = 0; i < feats.length; i++)
        {
          var feature = feats[i];
          var ec = m_oLayer_Active.changeManager.removeFeature(feature.id, feature);
            m_oLayer_Active.getUndoManager().addEdit(
            {
                changeManager: m_oLayer_Active.changeManager,
                editChangeEvent: ec,
                canUndo : function() { return true; },
                canRedo : function() { return true; },
                getPresentationName : function()
                {
                    return "feature removed";
                },
                undo : function()
                {
                    this.changeManager.undo(this.editChangeEvent);
                },
                redo : function()
                {
                    this.changeManager.redo(this.editChangeEvent);
                }   
            });
        }
    }
    
    function clearSaveStatus() {
       document.getElementById("SaveResponse").innerHTML="";
    }
    
    function saveOrDiscardChanges() 
    {
      if (OM.isNull(m_oLayer_Active.changeManager)) {
        return;
      }
      if(m_oLayer_Active.changeManager.hasChanges() === true) {
        if (confirm('Save changes? (click OK to Save, Cancel to Discard changes)')) {
            save();
        } else if(OM.notNull(m_oLayer_Active.changeManager)) {
            // need to undo all changes
            while(OM.notNull(m_oLayer_Active.getUndoManager().editToUndo())) {
              m_oLayer_Active.getUndoManager().undo();
            } 
        } 
      }
    }
    
    function save()
    {  
        if(OM.notNull(m_oLayer_Active.changeManager))
        {
          if(m_oLayer_Active.changeManager.hasChanges() === false) {
            document.getElementById("SaveResponse").innerHTML="No changes to save!";
            setTimeout(clearSaveStatus,1000);
          } else {
            m_oLayer_Active.saveEditing(saveCallBack);  // applies to JDBC and PREDEFINED layers
          }
        }
    }
