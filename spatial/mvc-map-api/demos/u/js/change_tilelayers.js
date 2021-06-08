    var layer21;
    var layer22;
    var layer23;
    var layer24;
    var layer31;
    var layer32;
    var layer33;
    var layer34;
    var map;
    var baseURL=document.location.protocol +"//"+ document.location.host+"/mapviewer";    

    function showMap()
    {
        map = new OM.Map(document.getElementById('map'),{mapviewerURL:baseURL});        
        
        var myradiobtn = document.getElementById('radioBtn31');
        myradiobtn.checked = true;
        radio_selTileLayer(myradiobtn);        
        map.setMapCenter(new OM.geometry.Point(-100, 35, 8307));  // all
        map.setMapZoomLevel(4);
        map.init() ;
        addMapControls(map);    
    }
    
    function checkBox_Toggle(checkBox){   
        var id = checkBox.id;
        var checkBox = document.getElementById(id);
        if (id === "checkBox21") {
            if (OM.isNull(layer21)) {
                layer21 = new OM.layer.VectorLayer("layer21", {def:{type:OM.layer.VectorLayer.TYPE_PREDEFINED, 
                                                dataSource:"mvdemo", theme:"THEME_DEMO_STATES", 
                                              url: baseURL},
                                       boundingTheme:true});
                map.addLayer(layer21);
            } else {
                map.removeLayer(layer21);
                layer21 = null;
            }
        }else if (id === "checkBox22") {
            if (OM.isNull(layer22)) {
                layer22 = new OM.layer.VectorLayer("layer22", {def:{type:OM.layer.VectorLayer.TYPE_PREDEFINED, 
                                                    dataSource:"mvdemo", theme:"THEME_DEMO_COUNTIES", 
                                                    url: baseURL},
                                             boundingTheme:true});
                map.addLayer(layer22);
            } else {
                map.removeLayer(layer22);
                layer22 = null;
            }
        }else if (id === "checkBox23") {
            if (OM.isNull(layer23)) {
                layer23 = new OM.layer.VectorLayer("layer23", {def:{type:OM.layer.VectorLayer.TYPE_PREDEFINED, 
                                                    dataSource:"mvdemo", theme:"THEME_DEMO_CITIES", 
                                                    url: baseURL},
                                             boundingTheme:true});
                map.addLayer(layer23);
            } else {
                map.removeLayer(layer23);
                layer23 = null;
            }
        }else if (id === "checkBox24") {
            if (OM.isNull(layer24)) {
                layer24 = new OM.layer.VectorLayer("layer24", {def:{type:OM.layer.VectorLayer.TYPE_PREDEFINED, 
                                            dataSource:"mvdemo", theme:"CUSTOMERS",
                                            url: baseURL},
                                             boundingTheme:true});
                map.addLayer(layer24);
            } else {
                map.removeLayer(layer24);
                layer24 = null;
            }
        }
    }
    
    function radio_selTileLayer(radio){   
        var id = radio.id;
        if (id === "radioBtn31") {
            if (OM.notNull(layer32) ) {
              map.removeLayer(layer32);
              layer32=null;
            }
            if (OM.notNull(layer33) ) {
              map.removeLayer(layer33);
              layer33=null;
            }
            if (OM.notNull(layer34) ) {
              map.removeLayer(layer34);
              layer34=null;
            }
            
            if (OM.isNull(layer31)) {
               layer31 = new OM.layer.ElocationTileLayer("eloc");
            }
            map.addLayer(layer31);
        } else if (id === "radioBtn32") {
            if (OM.notNull(layer31) ) {
              map.removeLayer(layer31);
              layer31=null;
            }
            if (OM.notNull(layer33) ) {
              map.removeLayer(layer33);
              layer33=null;
            }
            if (OM.notNull(layer34) ) {
              map.removeLayer(layer34);
              layer34=null;
            }
            
            if (OM.isNull(layer32)) {
               layer32 = new OM.layer.TileLayer(
                        "bi_world_map", 
                        {
                            dataSource:"ELOCATION_MERCATOR", 
                            tileLayer:"bi_world_map", 
                            tileServerURL: "https://elocation.oracle.com/mapviewer/mcserver",
                        });
        
            }
            map.addLayer(layer32);
        } else if (id === "radioBtn33") {
            if (OM.notNull(layer32) ) {
              map.removeLayer(layer32);
              layer32=null;
            }
            if (OM.notNull(layer34) ) {
              map.removeLayer(layer34);
              layer34=null;
            }
            if (OM.notNull(layer31) ) {
              map.removeLayer(layer31);
              layer31=null;
            }
            
            if (OM.isNull(layer33)) {
              layer33 =  new OM.layer.TileLayer(
                        "osm_positron", 
                        {
                            dataSource:"ELOCATION_MERCATOR", 
                            tileLayer:"osm_positron",
                            tileServerURL: "https://elocation.oracle.com/mapviewer/mcserver",
                        });
            }
            map.addLayer(layer33);
        } else if (id === "radioBtn34") {
            if (OM.notNull(layer32) ) {
              map.removeLayer(layer32);
              layer32=null;
            }
            if (OM.notNull(layer33) ) {
              map.removeLayer(layer33);
              layer33=null;
            }
            if (OM.notNull(layer31) ) {
              map.removeLayer(layer31);
              layer31=null;
            }
            
            if (OM.isNull(layer34)) {
              layer34 = new OM.layer.TileLayer(
                            "osm_dark", 
                            {
                                dataSource:"ELOCATION_MERCATOR", 
                                tileLayer:"osm_darkmatter", 
                                tileServerURL: "https://elocation.oracle.com/mapviewer/mcserver",
                            });
            }
            map.addLayer(layer34);
        }           
    }


//add map controls to the provided OM.Map instance
function addMapControls(map) {
        //addMapLayerControl(map);
        addMapNavControl(map)
        addMapCopyright(map);
        //addMapTitle(map);
        //addMapLegend(map);
        addMapScale(map);
        addToolBar(map);
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
        barThickness: 4,           // default is 3
        scaleBarColor: '#0000d0',  // default is black
        fontColor: '#0000d0'  // default is black
    };
    scaleBar.setStyle(sbStyle);

    //adds the scale bar to the map decoration
    map.addMapDecoration(scaleBar);   
  }
    
    function addMapTitle(map) {
    var maptitle = new OM.control.MapDecoration(null,
        { 
            anchorPosition: 2,
            title:" Map API Displaying OSM Maps",
            draggable:true, collapsible: false, 
            titleStyle:{ "font-size":"22px",
                         "font-weight":"bold",
                         "font-family":'Arial',
                         "color":"#0000d0",
                         "backgroundColor":"#c0c0c0",
                         "opacity":"0.75"                          
                        }
        });
    //adds the scale bar to the map decoration
    map.addMapDecoration(maptitle);
}    
        
function addMapScale(map) {
    //defines the basic properties for the map scale bars
    var sbConfig = {
        format: "BOTH",  // imperial and metric units
        anchorPosition: 4
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
      style: OM.control.NavigationPanelBar.STYLE_FULL
                    //STYLE_FULL
                    //STYLE_ZOOM_ONLY
                    //STYLE_ZOOM_BUTTONS_ONLY  //--default value
                    //STYLE_PAN_ONLY
                    //STYLE_PAN_AND_ZOOM_BUTTONS     
    };

    var navigationPanelBar = new OM.control.NavigationPanelBar(options);
        //navigationPanelBar.setZoomLevelInfoTips({
        //  2: "Country",
        //  5: "State",
        //  7: "City",
        //  15: "Street"
        //});
    //adds the scale bar to the map decoration
    map.addMapDecoration(navigationPanelBar);    
}
    
function addMapCopyright(map) {    
    var mapCopyRight = new OM.control.CopyRight({        
        anchorPosition:5,
        textValue:'©2020 Oracle Map API demos using <a href="https://www.openstreetmap.org/copyright" target="_blank">©OpenStreetMap</a>',
        fontSize:12,
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
    toolbar.setPosition(0.01, 0.01);
    map.addToolBar(toolbar);
}