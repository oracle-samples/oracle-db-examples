//This demo shows how to display a map tile layer. It also shows how to add various map controls
//such as a map navigation, a map scale, and a copyright note.

//Tile layers are background maps typically hosted by well known map service. Oracle also
//provides its own map services for use by various Oracle products and their customers.
//This is one of tile layers Oracle Maps Cloud Service provides.

//showMap is a wrapper function that includes all the mapping related logic
//for this demo. It is invoked in the document-ready function from its html page.

function showMap() {
    OM.gv.setResourcePath("https://elocation.oracle.com/mapviewer/jslib/v2.3");     // modify theis 
    //the DIV where the map lives; it needs to be passed into the map instance
    var mapDiv = document.getElementById('map');
    //create a map instance
    var map = new OM.Map(mapDiv);
    //create an instance of the OM.layer.ElocationTileLayer
    var tileLayer = new OM.layer.ElocationTileLayer();
    //Adds the tile layer to the map.  That's it!
    map.addLayer(tileLayer);
    
    // set the initial zoom level
    map.setMapZoomLevel(1);  // optional, default is level 0
    
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
    //addMapTitle(map);
    //addMapLegend(map);
    addMapScale(map);
}

function addMapNavControl(map) {
    var options = {
      anchorPosition: 1,
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
        textValue:'©2020 AskTom demos <a href="https://elocation.oracle.com/" target="_blank">Oracle Maps</a>',
        fontSize:10,
        fontFamily:'"Gill Sans","Helvetics Neue",Helvetica,Arial,sans-serif',
        fontColor:"#104a7e"      
    });
    //var mapCopyRight = new OM.control.CopyRight({anchorPosition:5,textValue:'Map data: <a href="https://www.naturalearthdata.com/" target="_blank"> Natural Earth </a>',fontSize:12,fontFamily:'Arial',fontColor:'black'});
    map.addMapDecoration(mapCopyRight);
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
    
function addMapTitle(map) {
    var maptitle = new OM.control.MapDecoration(null,
        { 
            anchorPosition: 2,
            title:"Oracle Maps Cloud Service World Map",
            draggable:true, collapsible: false, 
            titleStyle:{ "font-size":"22px",
                         "font-weight":"bold",
                         "font-family":'Arial',
                         "color":"#0000d0",
                         "backgroundColor":"#F0F0F0",
                         "opacity":"0.75"                          
                        }
        });
    //adds the scale bar to the map decoration
    map.addMapDecoration(maptitle);
}    
        
