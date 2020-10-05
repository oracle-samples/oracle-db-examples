var map = null;
var statesLayer = null, countiesLayer=null;
var stateCountyLayer = null;
var layerName="States";
var mapCenterLon = -20000;
var mapCenterLat =  1750000;
var mapZoom      =  2;  
var mpoint = new OM.geometry.Point(mapCenterLon,mapCenterLat,32775);
var currentPalette = null, currentStyle=null;
var myDefaultSty = 'YlBr5';//'Greys5';

var bucketRanges = {
"States3" : { buckets:3,
                    ranges: [
                       {lo:0, hi:1722850},
                       {lo:1722850, hi:4866692},
                       {lo:4866692, hi:500000000}
                    ]
                 },
"States5" : { buckets:5, 
                   ranges: [
                        {lo:0, hi:1006749},
                        {lo:1006749, hi:2573216},
                        {lo:2573216, hi:4219972},
                        {lo:4219972, hi:6478216},
                        {lo:6478216, hi:500000000}
                    ]
                 },
"Counties3" : { buckets:3,
                      ranges:[
                        {lo:0, hi:12823},
                        {lo:12823, hi:36882},
                        {lo:36882, hi:50000000}
                      ]
                     },
"Counties5" : { buckets:5,
                       ranges: [
                                     {lo:0, hi:10000},
                                     {lo:10000, hi:25000},
                                     {lo:25000, hi:60000},
                                     {lo:60000, hi:100000},
                                     {lo:100000, hi:50000000}
                       ]
                    }
};

/**
 * color series from ColorBrewer site (http://colorbrewer2.org/).
 */

var colorSeries = {
  
//multi-hue color scheme #10 YlBl.
  
"YlBl3": {   classes:3,
                 imgFileName:"mh10_3.png",
                 fill: [0xEDF8B1, 0x7FCDBB, 0x2C7FB8],
                 stroke:[0xB5DF9F, 0x72B8A8, 0x2872A6],
                 limit:[0xFAFDE8, 0xD9F0EB, 0xC0D9EA]
  },
  
"YlBl5": {   classes:5,
                 imgFileName:"mh10_5.png",
                 fill:[0xFFFFCC, 0xA1DAB4, 0x41B6C4, 0x2C7FB8, 0x253494],
                 stroke:[0xE6E6B8, 0x91BCA2, 0x3AA4B0, 0x2872A6, 0x212F85],
                 limit:[0xFFFFEB, 0xE3F1E8, 0xD9F0F3, 0xC0D9EA, 0xBEC2DF]
  },
  
//multi-hue color scheme #11 YlBr.
 
 "YlBr3": {classes:3,
                 imgFileName:"mh11_3.png",
                  fill:[0xFFF7BC, 0xFEC44F, 0xD95F0E],
                 stroke:[0xE6DEA9, 0xE5B047, 0xC5360D],
                 limit:[0xFFFDEB, 0xFFEDCA, 0xF4CFB7]
  
  },
  
"YlBr5": {classes:5,
                 imgFileName:"mh11_5.png",
                 fill:[0xFFFFD4, 0xFED98E, 0xFE9929, 0xD95F0E, 0x993404],
                 stroke:[0xE6E6BF, 0xE5C380, 0xE58A25, 0xC35663, 0x8A2F04],
                 limit:[0xFFFFF2, 0xFFF4DD, 0xFFE0BF, 0xF0BFC5, 0xE0C2B4]
    },
// single-hue color schemes (blues, greens, greys, oranges, reds, purples)
"Purples5": {classes:5,
                 imgFileName:"mh11_5.png",
                 fill:[0xf2f0f7, 0xcbc9e2, 0x9e9ac8, 0x756bb1, 0x54278f],
                 stroke:[0xd3d3d3, 0xd3d3d3, 0xd3d3d3, 0xd3d3d3, 0xd3d3d3],
                 limit:[0xFFFFF2, 0xFFF4DD, 0xFFE0BF, 0xF0BFC5, 0xE0C2B4]
    },
"Blues5": {classes:5,
                 imgFileName:"mh11_5.png",
                 fill:[0xEFF3FF, 0xbdd7e7, 0x68aed6, 0x3182bd, 0x18519C],
                 stroke:[0xd3d3d3, 0xd3d3d3, 0xd3d3d3, 0xd3d3d3, 0xd3d3d3],
                 limit:[0xFFFFF2, 0xFFF4DD, 0xFFE0BF, 0xF0BFC5, 0xE0C2B4]
    },
"Greens5": {classes:5,
                 imgFileName:"mh11_5.png",
                 fill:[0xedf8e9, 0xbae4b3, 0x74c476, 0x31a354, 0x116d2c],
                 stroke:[0xd3d3d3, 0xd3d3d3, 0xd3d3d3, 0xd3d3d3, 0xd3d3d3],
                 limit:[0xFFFFF2, 0xFFF4DD, 0xFFE0BF, 0xF0BFC5, 0xE0C2B4]
    },  
"Greys5": {classes:5,
                 imgFileName:"mh11_5.png",
                 fill:[0xf7f7f7, 0xcccccc, 0x969696, 0x636363, 0x454545],
                 stroke:[0xd3d3d3, 0xd3d3d3, 0xd3d3d3, 0xd3d3d3, 0xd3d3d3],
                 limit:[0xFFFFF2, 0xFFF4DD, 0xFFE0BF, 0xF0BFC5, 0xE0C2B4]
    },
"Oranges5": {classes:5,
                 imgFileName:"mh11_5.png",
                 fill:[0xfeedde, 0xfdb385, 0xfd8d3c, 0xe6550d, 0xa63603],
                 stroke:[0xd3d3d3, 0xd3d3d3, 0xd3d3d3, 0xd3d3d3, 0xd3d3d3],
                 limit:[0xFFFFF2, 0xFFF4DD, 0xFFE0BF, 0xF0BFC5, 0xE0C2B4]
    },
"Reds5": {classes:5,
                 imgFileName:"mh11_5.png",
                 fill:[0xfee5d9, 0xfcae91, 0xfb6a4a, 0xde2d26, 0xa50f15],
                 stroke:[0xd3d3d3, 0xd3d3d3, 0xd3d3d3, 0xd3d3d3, 0xd3d3d3],
                 limit:[0xFFFFF2, 0xFFF4DD, 0xFFE0BF, 0xF0BFC5, 0xE0C2B4]
    }
};

function showMap() {
    OM.gv.setResourcePath("../..");
    
    $('#demo-htmlselect').ddslick({
        width:      "220px",
				background: "#cccccc",
				selectText: "Select color palette",
        onSelected: function () {
                    var ddData = $('#demo-htmlselect').data('ddslick');
                    displaySelectedData(ddData);
					}});

    var myUniv= new OM.universe.Universe(
      {
        srid : 32775,
        bounds : new OM.geometry.Rectangle(
                            -3280000, 170000, 2300000, 3200000, 32775),
        numberOfZoomLevels: 16
      });
    map = new OM.Map(
        document.getElementById('map'),
        { mapviewerURL: "http://localhost:8080mapviewer",
          universe: myUniv
        }) ;
    states();	  
	  addMapControls(map);
}



function createBucketColorStyle(colorName, colorSeries, rangeName, bucketRanges)
{
   var theBucketStyle;
   var bucketStyleDef;
   var theBuckets = [];
   var theStyles = [];
   var theColors = [];
   var aBucket, aStyle, aColor, aRange;
   var numClasses ;

   numClasses = colorSeries[colorName].classes;

  // create buckets
   for (var i=0; i < numClasses; i++) {
      aBucket = new OM.style.RangedBucket(
      { low:bucketRanges[rangeName].ranges[i].lo, 
        high:bucketRanges[rangeName].ranges[i].hi
      });

      theBuckets.push(aBucket);      
   };
   
   // create Styles
   for (var i=0; i < numClasses; i++) {
        theStyles[i] = new OM.style.Color(
                     {fill: colorSeries[colorName].fill[i], 
                       stroke:colorSeries[colorName].stroke[i],
                      strokeOpacity: 1
                     });
   };

   bucketStyleDef = {
      numClasses : colorSeries[colorName].classes,
      classification: 'custom',  //since we are supplying all the buckets
      buckets: theBuckets,
      styles: theStyles,
      gradient:  'off'
      //gradient:  useGradient? 'radial' : 'off'
    };


   theBucketStyle = new OM.style.BucketStyle(bucketStyleDef);


   return theBucketStyle;
}

function states()
{
     layerName = "States";
     
     if(statesLayer) 
     { 
       if(countiesLayer) 
         countiesLayer.setVisible(false);
       // states where already visible with a white outline
       // set the style to the currently selected one
       //  statesLayer.setVisible(true);
       var theDDdata = $('#demo-htmlselect').data('ddslick');
       setStyle(theDDdata.selectedData.value); 
     }
     else 
     {
     
     var  layer2 = new OM.layer.VectorLayer("vLayer2", 
        {
          def:
          {
            type: OM.layer.VectorLayer.TYPE_PREDEFINED, 
            dataSource: "mvdemo", 
            theme: "us_states_bi", 
            url: "http://localhost:8080/mapviewer",
            loadOnDemand: false
          },
          boundingTheme:true
  	  });

   // add drop shadow effect and hover style
   var shadowFilter = new OM.visualfilter.DropShadow({opacity:0.5, color:"#000000", offset:6, radius:10});
 //  layer2.setVisualFilter(shadowFilter);

   var hoverStyle = new OM.style.Color(
        {stroke:"#FFFFFF", strokeThickness:2});
         // remove fill so that the thematic fill is preserved when on hover
         //{fill:"#D95F0E", stroke:"#EFA95B", strokeThickness:1});

   layer2.setHoverStyle(hoverStyle);
   layer2.setHoverVisualFilter(shadowFilter);

   layer2.enableFeatureHover(true);

   layer2.enableFeatureSelection(false);
   layer2.setLabelsVisible(true);
 
// override rendering style with programmatic one

   var theRenderingStyle = 
     createBucketColorStyle(myDefaultSty, colorSeries, 'States5', bucketRanges, true);

   layer2.setRenderingStyle(theRenderingStyle);
  
   currentPalette = myDefaultSty;

   var stLayerIdx =   map.addLayer(layer2);
   //alert('State Layer Idx = ' + stLayerIdx);

    map.setMapCenter(mpoint);
  
   map.setMapZoomLevel(mapZoom) ;
   
   //map.hideOverviewMap();
   map.init() ;

   statesLayer=layer2;

   // add rt-click event listener
   layer2.addListener(OM.event.MouseEvent.MOUSE_RIGHT_CLICK, stateRtClick);
   } // end if 

} // end states


function setStyle(styleName) 
{
  // alert("Selected Style = " + styleName);

  var newRenderingStyle = null; 
  if (layerName === "States") 
  {
    if(/3/.test(styleName)) 
    {
     newRenderingStyle = 
     createBucketColorStyle(styleName, colorSeries, 'States3', bucketRanges, false);
	   currentStyle = createBucketColorStyle(styleName, colorSeries, 'Counties3', bucketRanges, false);
    }
    else 
    {
     newRenderingStyle = 
     createBucketColorStyle(styleName, colorSeries, 'States5', bucketRanges, false);
	   currentStyle = createBucketColorStyle(styleName, colorSeries, 'Counties5', bucketRanges, false);
    }   
    statesLayer.setRenderingStyle(newRenderingStyle);
	if (stateCountyLayer)
	  stateCountyLayer.setRenderingStyle(currentStyle, ["TOTPOP"]);
  } else if (layerName === "Counties") {
    if(/3/.test(styleName)) {
     newRenderingStyle = 
     createBucketColorStyle(styleName, colorSeries, 'Counties3', bucketRanges, false);
    } else {
     newRenderingStyle = 
     createBucketColorStyle(styleName, colorSeries, 'Counties5', bucketRanges, false);
    }   

    countiesLayer.setRenderingStyle(newRenderingStyle);
    //currentStyle = newRenderingStyle;
  }
} // end setStyle

function stateRtClick(evt){
  var foi = evt.feature;
  // display another layer with counties info 
  // layer may change on each rt-click so create and add each time.
  var countyByState = null ;
  
  if (currentStyle === null)
    currentStyle = createBucketColorStyle(myDefaultSty, colorSeries, 'Counties5', bucketRanges, false);

  // remove existing layer 
  if(stateCountyLayer) 
    map.removeLayer(stateCountyLayer);

  countyByState = new OM.layer.VectorLayer("stCountyLayer", 
                  {def:{type: OM.layer.VectorLayer.TYPE_JDBC,
                   dataSource: "mvdemo",
                   sql: "select county,totpop,geom32775 from counties_32775_moved where state_abrv="+
                        "'"+foi.getAttributeValue('_label_')+"'",
                   url: "http://localhost:8080/mapviewer"}});			   


  countyByState.setVisible(true);
  countyByState.setRenderingStyle(currentStyle, ["TOTPOP"]);

  map.addLayer(countyByState);  

  //map.addLayer(countyByState);
  stateCountyLayer = countyByState;
} // end stateRtClick

function displaySelectedData(ddData)
{
   // if only testing ddslick by itself then alert else do required tasks
   if(map) 
   {
      // code to update renderStyle goes here
	  //alert('will try to change render style');
	  setStyle(ddData.selectedData.value);
   }
   else
   {
    // do nothing 
   }
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
              title:"  State Pop. Density and County Population",
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