function showMap() {
    OM.gv.setResourcePath("https://elocation.oracle.com/mapviewer/jslib/v2.3");// need to modify to eloc
    var mapDiv = document.getElementById('map');
    var map = new OM.Map(mapDiv);
    var tileLayer = new OM.layer.OSMTileLayer( "baseMap");
    map.addLayer(tileLayer);

    map.setMapZoomLevel(1);
    map.init();
    addMapControls(map);        
};

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