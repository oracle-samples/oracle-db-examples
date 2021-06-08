function showMap() {
    OM.gv.setResourcePath("https://elocation.oracle.com/mapviewer/jslib/v2.3");
    
    //This is the DIV that will display the map; it needs to be passed into
    //the map instance.
    var mapDiv = document.getElementById('map');
    var map = new OM.Map(mapDiv);
   
    var tileLayer = new OM.layer.HereTileLayer("HERE tile layer",
        {
            appCode:"your-appCode-obtained-from-HERE",
            appID:"your-appID-obtained-from-HERE",
            libURL:"http://js.api.here.com/v3/3.0",
            useHTTPS: false, //true,
            useCIT: false,  //The CIT environment is not intended for general production use.
            mapTypeList:"OM.layer.HereTileLayer.TYPE_NORMAL_MAP;OM.layer.HereTileLayer.TYPE_SATELLITE_MAP;OM.layer.HereTileLayer.TYPE_TERRAIN_MAP",
            mapTypeVisible: true,  // default is true
            mapType: OM.layer.HereTileLayer.TYPE_TERRAIN_MAP
        });
    

    map.addLayer(tileLayer);

    // set the initial zoom level
    map.setMapZoomLevel(5);
    map.setMapCenter(new OM.geometry.Point(-110,38)) ;
    //Now we can complete the initialization of the map. You must
    //only call this method once.  Note however map layers can
    //be added even after calling this method.
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
        //addToolBar(map);
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
            title:" Map API Displaying HERE Maps",
            draggable:true, collapsible: false, 
            titleStyle:{ "font-size":"22px",
                         "font-weight":"bold",
                         "font-family":'Arial',
                         "color":"#0000d0",
                         "backgroundColor":"#d0d0d0",
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
        anchorPosition: 6
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
        textValue:'©2020 Map API demos using <a href="https://legal.here.com/us-en/terms" target="_blank">©HERE Maps</a>',
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
    toolbar.setPosition(0, 0);
    map.addToolBar(toolbar);
}