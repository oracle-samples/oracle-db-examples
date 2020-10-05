    var colorScheme;
    function showMap() {
        //the DIV where the map lives; it needs to be passed into the map instance
        var mapDiv = document.getElementById('map');
        //create a map instance
        var map = new OM.Map(mapDiv);

        var tileLayer = new OM.layer.ElocationTileLayer("my_background_map", 
                            {
                              //layerName: 'WORLD_MAP'  // default
                              //layerName: 'BI_WORLD_MAP'
                              layerName: 'BI_WORLD_MAP_LIGHT'
                            });
        map.addLayer(tileLayer) ;
        
        //add jdbc vector layer for population density using color ramp
        addDensityLayer(map);  
        //add jdbc vector layer for population using markers
        addMarkerLayer(map);
        map.setMapCenter(new OM.geometry.Point(-105,36) );
        map.setMapZoomLevel(3) ;
        map.init() ;
        addMapControls(map);
    }
    
    function addDensityLayer(map) {
        var layer = new OM.layer.VectorLayer("Population Density", {
                def:{
                    type: OM.layer.VectorLayer.TYPE_JDBC, 
                    dataSource: "mvdemo", 
                    sql: "select state, POPPSQMI, geom  from states", 
                    url: "http://localhost:8080/mapviewer",
                    loadOnDemand: true // only load the data if in viewport
                },
                renderingStyle: getColorScheme(),
                styleAttributes:['POPPSQMI']
            });
        map.addLayer(layer);
    }
    
    function addMarkerLayer (map) {
        var styVarMarkers = new OM.style.VariableMarker({
            classification: "equal",
            marker: new OM.style.Marker({
                vectorDef: [{
                    shape: { type: "circle", cx: 5, cy: 5, width: 10, height: 10 },
                    style: { fill: "#008080", strokeThickness:2, stroke: "#ffffff", fillOpacity: 0.85 }
                }]
                //textStyle: new OM.style.Text({ fill: "#000000" })
            }),
            startSize: 30,
            increment: 10,
            numClasses: 6
        });
        var textStyle = new OM.style.Text({
            styleName: "markerText",
            fill: "#ffffff",
            fontStyle: OM.Text.FONTSTYLE_ITALIC,
            fontWeight: OM.Text.FONTWEIGHT_BOLD,
            fontSize: 12,
            sticky: true
          })
     
         var layer_MarkerWithText = new OM.layer.VectorLayer("Total Population", {
            def:{type: OM.layer.VectorLayer.TYPE_JDBC, 
                dataSource: "mvdemo", 
                sql: "select state_abrv, totpop, geom  from states", 
                url: "http://localhost:8080/mapviewer",
                loadOnDemand: true,
                labelColumn: "STATE_ABRV"
            },
            renderingStyle: styVarMarkers,
            //styleAttributes:['POPPSQMI']
            styleAttributes:["TOTPOP"]
        });
        layer_MarkerWithText.setBringToTopOnMouseOver(true);
        layer_MarkerWithText.setLabelingStyle(textStyle);
     
        map.addLayer(layer_MarkerWithText);          
    }

    /**
     * Returns an array. Each element defines the lower and upper bound of populatin density
     * @returns {Array} a custom edited JSON array. 
     */
    function getRangeBuckegArray () {
      return [  
          {low:0,   high:10},
          {low:10,  high:50},
          {low:50,  high:250},
          {low:250, high:500},
          {low:500, high:99999}
        ];
    }
    
    /**
     * Returns the color scheme 
     * @returns {OM.style.ColorScheme} the color scheme
     */
    function getColorScheme() {
        if (colorScheme) {
          return colorScheme;
        }
        
        var ra = getRangeBuckegArray();
        var buckets = []
        for (var i=0; i<ra.length; i+=1) {
            var bucket = new OM.style.RangedBucket({ seq:i, low: ra[i].low, high:ra[i].high});
            buckets.push(bucket);
        }
        colorScheme = new OM.style.ColorScheme({
                fromColor : "#08FF00",
                toColor : "#FF0505",
                stroke: "#000000",
                baseColorOpacity: 0.6,
                strokeOpacity: 0.6,
                fillOpacity: 0.7,
                classification: 'custom',
                //classification: 'equal',  
                //classification: 'logarithmic',  
                buckets: buckets,//[bucket0, bucket1, bucket2, bucket3, bucket4], //if bucket is provide, it precedes the classification method(?)
                numClasses: 5
              });
        return colorScheme;
    }         
    function addMapControls(map) {
        addMapLayerControl(map);
        addMapNavControl(map)
        addMapCopyright(map);
        addMapTitle(map);
        addMapLegend(map);
        addMapScale(map);
    }
    
    function addMapLegend(map) {
        var str = "<table style='width:150px;'>";
        var ra = getRangeBuckegArray();
        var colorStops = getColorScheme().getColorStops(); // array of colos
        for (var i=0; i<ra.length; i+=1) {
          str += "<tr><td><div style='width:15px;height:15px;background-color:"+
                  colorStops[i]+"'/></td><td>" + ra[i].low+"..." + ra[i].high + "</td></tr>"
        }
        str += "</table>";
        var legend = new OM.control.MapDecoration(str,
            { anchorPosition:4,
              title:"Pop. Density",
              draggable:true,
              titleStyle:{"opacity":"1.0",
                          "border-color":"#000000",
                          "border-width":"1px",
                          "font-weight":"bold",
                          "text-align":"center",
                          "font-family":'Courier New',
                          "backgroundColor":"#A0A0A0"
                         },
              contentStyle:{"opacity":"0.7","backgroundColor":"#EAEAEA"}
            });
        map.addMapDecoration(legend);
    }
    
    function addMapTitle(map) {
      var maptitle = new OM.control.MapDecoration(null,
          { 
              anchorPosition: 2,
              title:"  State Population and Population Density",
              draggable:true, collapsible: false, 
           titleStyle:{ "font-size":"22px",
                         "font-weight":"bold",
                         "font-family":'Arial',
                         "color":"#0000d0",
                         "backgroundColor":"#FfFfFf",
                         "opacity":"0.95"                          
                        }
          });
        map.addMapDecoration(maptitle);
    }    
        
    function addMapScale(map) {
        //defines the basic properties for the map scale bars
        var sbConfig = {
            format: "BOTH",  // imperial and metric units
            anchorPosition: 6
        };

        //creates the actual sacle bar instance and sets the display style
        var scaleBar = new OM.control.ScaleBar(sbConfig);

        //defines the display style of the scale bars
        var sbStyle = {
            barThickness:6,           // default is 3
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
          style: OM.control.NavigationPanelBar.STYLE_PAN_AND_ZOOM_BUTTONS,
                        //STYLE_FULL
                        //STYLE_ZOOM_ONLY
                        //STYLE_ZOOM_BUTTONS_ONLY  //--default value
                        //STYLE_PAN_ONLY
                        //STYLE_PAN_AND_ZOOM_BUTTONS                           
          backgroundColor: "#FF0000"
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
        var mapCopyRight = new OM.control.CopyRight({anchorPosition:5,textValue:'Map data: <a href="https://www.naturalearthdata.com/" target="_blank"> Natural Earth </a>',fontSize:12,fontFamily:'Arial',fontColor:'black'});
        map.addMapDecoration(mapCopyRight);
    }