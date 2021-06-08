function showMap() {
    OM.gv.setResourcePath("../..");

    var mapDiv = document.getElementById('map');

    var map = new OM.Map(mapDiv);

    //This is how an offline tile layer is created:
    //You specify the locally stored tiles location, and indicate that this is a local tile layer.
    var tileLayer = new OM.layer.TileLayer("my_offline_layer", 
              { 
                tileImagesURL : "../../tests/tilelayers/MVDEMO.WMTS_E4_FLATMESH", 
                isLocalTileLayer : "true"
              });
        
    //Adds the tile layer to the map.  That's it!
    map.addLayer(tileLayer);

    // set the initial zoom level
    map.setMapZoomLevel(7);
    map.setZoomLevelRange(2, 8);
    //Now we can complete the initialization of the map. You must
    //only call this method once.  Note however map layers can
    //be added even after calling this method.
    map.setMapCenter(new OM.geometry.Point(-120,38) );  // also supports (-13580978, 4579425.81,3857)
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
        //addToolBar(map);
}

function addMapTitle(map) {
    var maptitle = new OM.control.MapDecoration(null,
        { 
            anchorPosition: 2,
            title:"Map Viz Offline Tile Layer",
            draggable:true, 
            titleStyle:{ "font-size":"22px",
                         "font-weight":"bold",
                         "font-family":'Arial',
                         "color":"#0000d0",
                         "backgroundColor":"#fffff0",
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
      anchorPosition: 1,
      style: OM.control.NavigationPanelBar.STYLE_ZOOM_BUTTONS_ONLY
                    //STYLE_FULL
                    //STYLE_ZOOM_ONLY
                    //STYLE_ZOOM_BUTTONS_ONLY  //--default value
                    //STYLE_PAN_ONLY
                    //STYLE_PAN_AND_ZOOM_BUTTONS                           
    };

    var navigationPanelBar = new OM.control.NavigationPanelBar(options);
    //adds the scale bar to the map decoration
    map.addMapDecoration(navigationPanelBar);    
}
    
function addMapCopyright(map) {    
    var mapCopyRight = new OM.control.CopyRight({        
        anchorPosition:5,
        textValue:'©2020 Map API offline tile layer demo',
        fontSize:12,
        fontFamily:'"Gill Sans","Helvetics Neue",Helvetica,Arial,sans-serif',
        fontColor:"#104a7e"      
    });
    //var mapCopyRight = new OM.control.CopyRight({anchorPosition:5,textValue:'Map data: <a href="https://www.naturalearthdata.com/" target="_blank"> Natural Earth </a>',fontSize:12,fontFamily:'Arial',fontColor:'black'});
    map.addMapDecoration(mapCopyRight);
}
//
//function addToolBar(map) {    
//    var toolbar = new OM.control.ToolBar("toolbar1", 
//    {
//      builtInButtons : [OM.control.ToolBar.BUILTIN_ALL]
//    });
//    toolbar.setPosition(0, 0);
//    map.addToolBar(toolbar);
//}
