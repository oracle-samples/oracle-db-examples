    function showMap() {
      var map = new OM.Map(document.getElementById('map')) ;

      var tileLayer = new OM.layer.ElocationTileLayer("oracle_tilelayer", 
                                  {"layerName": "BI_WORLD_MAP_LIGHT"
                                });//  'WORLD_MAP', 'BI_WORLD_MAP', or 'BI_WORLD_MAP_LIGHT'.
      map.addLayer(tileLayer);
      addLayer_Polygons(map);
      addLayer_Lines(map);
      addLayer_Points(map);
      map.setMapCenter(new OM.geometry.Point(-118,34,8307) );
      map.setMapZoomLevel(8) ;
      map.init() ;
      //Adds various map controls to the map.
      addMapControls(map);
    };

    //add map controls to the provided OM.Map instance
    function addMapControls(map) {
      addMapLayerControl(map);
      addMapNavControl(map)
      addMapCopyright(map);
      addMapScale(map);
      addToolBar(map);
    }
    
    function addLayer_Points(map) {
      // the POI data set
      var style_food = {"textColor":"000000","text":"F","color":"B6EB79"};
      var style_hotel = {"textColor":"000000","text":"H","color":"79B6EB"};
      var style_scene = {"textColor":"000000","text":"S","color":"5DBE3F"};
      var style_parking = {"textColor":"000000","text":"P","color":"FFDE00"};
      var markersData = [
        {"x":-122.26246,"y":37.5307,"id":"1","name":"Orcle Cafeteria","type":"FOOD","style": style_food}
       ,{"x":-122.301113,"y":37.556272,"id":"2","name":"San Mateo Marriott","type":"HOTEL","style":style_hotel}
       ,{"x":-118.664078,"y":36.591072,"id":"3","name":"Alta peak","type":"SCENE","style":style_scene}
       ,{"x":-118.765588,"y":36.546872,"id":"4","name":"Moro Rock","type":"SCENE","style":style_scene}
       ,{"x":-122.263637,"y":37.531705,"id":"5","name":"Orale 420 Garage","type":"PK","style":style_parking}
       ,{"x":-118.734787,"y":36.596239,"id":"6","name":"Trail Head","type":"PK","style":style_parking}
      ];

      var fillColor = {"F":"B6EB79",
                       "H":"79B6EB",
                       "S":"5DBE3F",
                       "P":"FFDE00"};
      var vecLayer1 = new OM.layer.VectorLayer("FOIs", {
                                              def: {type: OM.layer.VectorLayer.TYPE_LOCAL},
                                              boundingTheme : true
                                              });

        markersData.forEach(function (marker){
          var point = new OM.geometry.Point(marker.x, marker.y);
          var path1= "M11.894,32.906c-1.053-6.41-4.529-10.265-7.82-13.417C2.1,17.598,1.009,14.972,1,12.093C0.992,9.111,2.203,6.224,4.323,4.17C6.433,2.126,9.189,1,12.083,1c2.881,0,5.601,1.123,7.658,3.162c2.111,2.093,3.3,4.995,3.259,7.962c-0.039,2.864-1.179,5.492-3.21,7.397C16.465,22.645,12.954,26.469,11.894,32.906z";
          path1 = path1.replace(/([0-9])([\-])/g, '$1 $2'); //ensure there is a space separating negative numbers

          m1 = new OM.style.Marker({
                vectorDef : [
                    {shape:{type: "svg",  svgPath:path1 }, 
                     style: {fill:fillColor[marker.style.text], stroke:"#2d1d85", strokeThickness:'2'}
                    }
                ],
                width: 24,
                height: 37,
                yOffset: -16,
                textStyle:{fontSize:14, fontWeight:OM.Text.FONTWEIGHT_NORMAL},
                textOffset:{x:0, y:-8},
            });
        var markerOpt = {renderingStyle: new OM.style.Marker(m1)};
        var feature = new OM.Feature(marker.id, point, markerOpt);

          feature.setVisible(true);
          feature.setMarkerText(marker.style.text);
          feature.attributes = {"ID":marker.id, "TYPE":marker.type, "NAME":marker.name};
          vecLayer1.addFeature(feature);
        });

      vecLayer1.setBringToTopOnMouseOver(true);   
      var hoverStyle = new OM.style.Color({
                    fill: "#FF0000", 
                });
      var selectStyle = new OM.style.Color({
                    fill: "#00ff00", 
                });                

    map.addLayer(vecLayer1);    
    vecLayer1.enableToolTip(false);   
    vecLayer1.setHoverStyle(hoverStyle);
    vecLayer1.setSelectStyle(selectStyle);
  }

  function addLayer_Lines(map) {
    var l1 = new OM.style.Line(
            {   styleName:"myLineSty1",
                stroke:"#0000cf",
                strokeThickness:7,
                strokeOpacity: 1.0,
                centerLine:"#ffff00", 
                centerLineWidth:3,                     
                strokeLineCap: OM.LineCaps.ROUND,
                centerLineDash:[7,7],
            });
    var l2 = new OM.style.Line(
            {   styleName:"myLineSty2",
                stroke:"#00cf00", 
                strokeThickness:5, 
                strokeOpacity: 1.0,
                centerLine:"#ffff00", 
                centerLineWidth:3, 
                strokeLineCap: OM.LineCaps.BUTT,
                centerLineDash:[3,3]
            });
    var l3 = new OM.style.Line(
            {   styleName:"myLineSty0",
                stroke:"#ff0000",
                strokeThickness:4, 
                strokeOpacity: 1.0,
                strokeLineCap: OM.LineCaps.BUTT,
                strokeDash:[4,4]
            });

    var c1 = new OM.style.CollectionBucket({
              values:["ROAD"]
            });
            var c2 = new OM.style.CollectionBucket({
              values:["PATH"]
            });
            var c3 = new OM.style.CollectionBucket({
              values:["TRAIL"]
            });

    var cStyle = new OM.style.BucketStyle({
      buckets:[c1, c2, c3],
      styles:[l1, l2, l3]
    });      
    var hoverStyle = new OM.style.Line({stroke:"#ff0000",strokeThickness:5});
    var selectStyle = new OM.style.Line({stroke:"#00ff00",strokeThickness:5});

    var vecLayer2 = new OM.layer.VectorLayer("Paths", 
        { def:{
            type: OM.layer.VectorLayer.TYPE_DATAPACK, 
            url: "data/apexmaps_lines.json"
          },
          renderingStyle: cStyle,
          styleAttributes:['TYPE']
        });
//    var vecLayer2 = new OM.layer.VectorLayer("Roads&Tails", 
//                { def:{
//                      type: OM.layer.VectorLayer.TYPE_JDBC, 
//                      dataSource:"apexmaps", 
//                      sql: "select ID, TYPE, NAME, GEOM  from lines", 
//                      url: location.protocol + "//"+ location.host+"/mapviewer"
//                  },
//                  //boundingTheme: true,
//                  renderingStyle: cStyle,
//                  styleAttributes:['TYPE']
//                });
      vecLayer2.setBringToTopOnMouseOver(true);   
      vecLayer2.setHoverStyle(hoverStyle);
      vecLayer2.setSelectStyle(selectStyle);
      
      map.addLayer(vecLayer2) ;
      vecLayer2.bringToTop();
      vecLayer2.enableToolTip(false);   
    }
    
    function addLayer_Polygons(map) {
      var s1 = new OM.style.Color({
                  fill:"ffef00", 
                  fillOpacity:0.5, 
                  stroke:"#009900", 
                  strokeThickness:3, 
                  strokeOpacity:0.75, 
                  strokeDash:[3,1]
              });      
      var s2 = new OM.style.Color({
                  fill:"e70000", 
                  fillOpacity:0.5, 
                  stroke:"#009900", 
                  strokeThickness:3, 
                  strokeOpacity:0.75, 
                  strokeDash:[3,1]
              });
      var s3 = new OM.style.Color({
                  fill:"00811f",
                  fillOpacity:0.5, 
                  stroke:"#000000", 
                  strokeThickness:3, 
                  strokeOpacity:0.75, 
                  strokeDash:[3,1]
              });

      var s4 = new OM.style.Color({
                  fill:"0044ff", 
                  fillOpacity:0.5, 
                  stroke:"#009900", 
                  strokeThickness:3, 
                  strokeOpacity:0.75, 
                  strokeDash:[3,1]
              });

      var hoverStyle = new OM.style.Color({
                  fill:"ff0000", 
                  fillOpacity:0.25, 
                  stroke:"#009900", 
                  strokeThickness:3, 
                  strokeOpacity:0.75, 
                  strokeDash:[3,1]
              });

      var selectStyle = new OM.style.Color({
                  fill:"00ff00", 
                  fillOpacity:0.25, 
                  stroke:"#009900", 
                  strokeThickness:3, 
                  strokeOpacity:0.75, 
                  strokeDash:[3,1]
              });

      var cb1 = new OM.style.CollectionBucket({
          values:["Sequoia National Park"]
        });
      var cb2 = new OM.style.CollectionBucket({
        values:["Yosemite National Park"]
      });
      var cb3 = new OM.style.CollectionBucket({
        values:["Redwood National PARK"]
      });
      var cb4 = new OM.style.CollectionBucket({
        values:["Death Valley National Park"]
      });

      var cStyle = new OM.style.BucketStyle({
        buckets:[cb1, cb2, cb3, cb4],
        styles:[s1, s2, s3, s4]
      });      


      var vecLayer3 = new OM.layer.VectorLayer("Parks", 
        { def:{
            type: OM.layer.VectorLayer.TYPE_DATAPACK, 
            url: "data/apexmaps_polygons.json"
          },
          //boundingTheme: true,
          renderingStyle: cStyle,
          styleAttributes:['NAME']
        });
//      var vecLayer3 = new OM.layer.VectorLayer("Parks", 
//        { def:{
//              type: OM.layer.VectorLayer.TYPE_JDBC, 
//              dataSource:"apexmaps", 
//              sql: "select ID, TYPE, NAME, GEOM  from polygons", 
//              url: location.protocol + "//"+ location.host+"/mapviewer"
//          },
//          boundingTheme: true,
//          renderingStyle: cStyle,
//          styleAttributes:['NAME']
//        });
      vecLayer3.setBringToTopOnMouseOver(true);   
      vecLayer3.setHoverStyle(hoverStyle);   
      vecLayer3.setSelectStyle(selectStyle);   
      vecLayer3.enableToolTip(false);   

      map.addLayer(vecLayer3);
      vecLayer3.sendToBottom();
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
      anchorPosition: 3,
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
    //adds the scale bar to the map decoration
    map.addMapDecoration(navigationPanelBar);    
  }
    
  function addMapCopyright(map) {    
    var mapCopyRight = new OM.control.CopyRight({        
        anchorPosition:4,
        textValue:'©2020 Oracle APEX Office Hours; <a href="https://elocation.oracle.com/" target="_blank">Oracle Maps</a>',
        fontSize:10,
        fontFamily:'"Gill Sans","Helvetics Neue",Helvetica,Arial,sans-serif',
        fontColor:"#104a7e"      
    });
    //var mapCopyRight = new OM.control.CopyRight({anchorPosition:5,textValue:'Map data: <a href="https://www.naturalearthdata.com/" target="_blank"> Natural Earth </a>',fontSize:12,fontFamily:'Arial',fontColor:'black'});
    map.addMapDecoration(mapCopyRight);
  }

  function addToolBar(map) {    
    var toolbar = new OM.control.ToolBar("toolbar1", 
    {
      builtInButtons : [OM.control.ToolBar.BUILTIN_ALL]
    });
    toolbar.setPosition(0.45, 0);
    map.addToolBar(toolbar);
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
    
  