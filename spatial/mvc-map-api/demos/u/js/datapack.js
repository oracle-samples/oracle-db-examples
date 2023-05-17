function showMap() {
    OM.gv.setResourcePath("../..");
    
    var mapDiv = document.getElementById('map');
    var map = new OM.Map(mapDiv);

    var tileLayer = new OM.layer.ElocationTileLayer();

    map.addLayer(tileLayer);

    //creates the vector layer for the marker
    addVectorLayerDataPack(map);
  
    //set the initial map center and zoom level
    map.setMapCenter( new OM.geometry.Point(-122.48, 37.65));
    map.setMapZoomLevel(5);
    
    map.init();
    
    addMapControls(map);
};

function addVectorLayerDataPack(map)
{
  var nBuckets = 5;
  var colorStyles = [];

  //the series of RGB values to be used to fill the county polygons. It's the Yellow-Orange-Red series from colorbrewer.
  var colors = OM.style.colorbrewer.Oranges[nBuckets];

  //next let's create different color styles that will be associated with each bucket. Each county
  //will determine which bucket its population falls in, and the associated color style for that county polygon.
  for(i=0; i<nBuckets; i++) {  
    var fillColor = colors[i];
    colorStyles[i] = new OM.style.Color({
      fill: fillColor,
      fillOpacity:0.75,
      stroke: "#d39052"
    });
  }

  //now we have the buckets and the associated styles, let's put them into a single
  //advanced style, the type OM.style.BucketStyle.
  var bucketStyle = new OM.style.BucketStyle({

      // 5 buckets will be generated automatically, ranging from fewest population
      //to the most densely populated.
      numClasses: nBuckets,

      //this tells the bucket style that we want the population range to be 
      //divided into 7 buckets, but in a logarithmic scale. This is to avoid
      //the buckets being skewed by certain large counties with a huge population.
      classification: 'logarithmic',  // natural logarithm: e= 2.718281828459

      //for each generated bucket, a corresponding style from the styles array
      //will be assigned, from lowest population to the highest.
      styles: colorStyles
    });

  //creates the actual vector layer from the ca_county.json data pack file.
  var layer = new OM.layer.VectorLayer('county_population',  {
      def: {
               type: OM.layer.VectorLayer.TYPE_DATAPACK,               
               url: "data/ca_counties.json",               
               labelColumn: "COUNTY"      
           }
      });
    //ensure the feature's label text is displayed on the map
    layer.setLabelsVisible(true);
    
  //applies the advanced style to the layer. Note the very important second
  //parameter, which is an array of attribute or property names from the geoJson 
  //layer that will supply the actual numeric values required by the BucketStyle 
  //to determine the correct bucket for each feature. In this case we only need a single
  //attribute named TOTPOP from the geoJson layer's features.
  layer.setRenderingStyle(bucketStyle, ['TOTPOP']);

  //lets also set a hover style to indiciate which county is being hovered on.
  //Note that since this Color style didn't specify a Fill color, it will
  //'inherit' the Fill color of the normal rendering style (which is determined
  //by the bucketStyle). This is actually the effect we wanted.
  var hover = new OM.style.Color({stroke: "#4aaccb", strokeThickness: 2.5});
  layer.setHoverStyle(hover);

  //disable the info window which is displayed on mouse clicks.
  layer.enableInfoWindow(false);
  
  //instead we want to show a customized tooltip on mouse hover
  layer.enableFeatureHover(true)

  //By default, when you mouse over a feature, a simple tooltip will be displayed
  //showing the _LABEL_ field of the feature. If there is no such field then no
  //tooltip is displayed at all.
  //You can customize the tooltip using a function that returns the text
  //to be used as tooltip. The function will be called whenever a feature is 
  //being hovered on, and the feature itself is
  //passed into the function where the tooltip text can be assembled.
  layer.setToolTipCustomizer(function (feature) {
    //feature.attributes is an associative array of all the properties defined
    //on the feature. In this case they come from the geoJson file.
    var properties = feature.attributes;
    
    var tooltip =  {
          titlesArray   : [properties.COUNTY+',', properties.STATE_ABRV],
          headersArray  : ['Population'],
          contentsArray : [parseFloat(properties.TOTPOP)]
        };
    return tooltip;
  });
    
  //that's it. once we add this layer to the map, each county will first determine
  //its bucket based on its TOTPOP property, then the associated color style is
  //applied to the county's polygon.
  map.addLayer(layer);
}

function addMapControls(map) {
    addMapNavControl(map)
    addMapCopyright(map);
    addMapTitle(map);
    addMapScale(map);
}
    
    
    function addMapTitle(map) {
      var maptitle = new OM.control.MapDecoration(null,
          { 
              anchorPosition: 2,
              title:"  California County Population",
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
        var mapCopyRight = new OM.control.CopyRight({anchorPosition:5,textValue:'Map data: <a href="https://www.naturalearthdata.com/" target="_blank"> Natural Earth </a>',fontSize:12,fontFamily:'Arial',fontColor:'black'});
        map.addMapDecoration(mapCopyRight);
    }