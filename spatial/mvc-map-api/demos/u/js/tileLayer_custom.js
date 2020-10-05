function showMap() {
    OM.gv.setResourcePath("../..");
    
    //This is the DIV that will display the map; it needs to be passed into
    //the map instance.
    var mapDiv = document.getElementById('map');

    var map = new OM.Map(mapDiv);

    var tileLayer = new OM.layer.TileLayer("layer1", 
        { dataSource:"mvdemo", 
          tileLayer:"demo_map", 
          tileServerURL: "http://localhost:8080/mapviewer/mcserver"
        });

    map.addLayer(tileLayer);
    
    // set the initial zoom level
    map.setMapZoomLevel(5);  // optional, default is level 0
    map.setMapCenter(new OM.geometry.Point(-122.5, 38)); //in long/lat order // default is at 0,0

    //call this init() method once
    //Note map layers and map decorations can be added before or after invoking this map.init() method.
    map.init();    
    
    //Adds various map controls to the map.
    addMapControls(map);    
};

//add map controls to the provided OM.Map instance
function addMapControls(map) {
        //addMapLayerControl(map);
        addMapNavControl(map)
        addMapCopyright(map);
        addMapTitle(map);
        //addMapLegend(map);
        addMapScale(map);
        addToolBar(map);
}

function addMapTitle(map) {
    var maptitle = new OM.control.MapDecoration(null,
        { 
            anchorPosition: 2,
            title:"Map Viz Tile Layer",
            draggable:true, collapsible: false, 
            titleStyle:{ "font-size":"22px",
                         "font-weight":"bold",
                         "font-family":'Arial',
                         "color":"#0000d0",
                         "backgroundColor":"#a0a0a0",
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
        anchorPosition:5,
        textValue:'©2020 Map API demos of <a href="https://elocation.oracle.com/" target="_blank">Oracle Maps</a>',
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
    toolbar.setPosition(0, 0);
    map.addToolBar(toolbar);
}