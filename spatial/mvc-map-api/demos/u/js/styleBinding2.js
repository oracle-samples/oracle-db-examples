
// This tutorial is similar to styleBinding.html, but instead of binding
// the sales data to the bubbles' FILL colors, it binds them to the SIZE
// aspect of the bubbles. It also adds a second binding that sets the
// FILL color based on each customer's account_mgr.
// 
// This second binding also shows how to create a custom ColorFormatter
// which maps the manager names to colors.
// 
// finally, it also shows how to customize the info window that is 
// displayed when you click on a feature bubble.

function showMap() {
    OM.gv.setResourcePath("../..");
    
    //this defines a universe with the custom Albers-USA map projection that
    //scales and moves the states of Alaska and Hawii closer to the lower 48
    //states.
    var config = {
        //special srid 505050 represents the client-side only Albers-USA projection.
        srid : 505050, 

        //these bounds seem to give the best overall appearance
        bounds : new OM.geometry.Rectangle(-3200000, -500000, 2800000, 3800000, 505050),

        numberOfZoomLevels: 10
    };

    var albersUsa = new OM.universe.Universe(config);

    var map = new OM.Map(document.getElementById('map'),
                      {
                          universe: albersUsa
                      });


    //displays the background layer: counties of California from a geoJson data pack file
    var stateColor = new OM.style.Color(
            {   strokeThickness: 1,
                stroke: "#ac9898",
                fill: "#b2bec6",
                fillOpacity: 0.85});
    var stateLayer = new OM.layer.VectorLayer("states",
            {
                def: {
                    type: OM.layer.VectorLayer.TYPE_DATAPACK,
                    url: "../u/data/usa_states.json",
                    labelColumn: "state_abrv"
                },
                renderingStyle: stateColor,
                boundingTheme: false
            }
    );
    //ensure the feature's label text is displayed on the map
    stateLayer.setLabelsVisible(true);
    stateLayer.enableToolTip(false);

    map.addLayer(stateLayer);

    //add the customers bubble layer
    addCustomersLayer(map);
    
    map.init();
    addMapControls(map);
}

//creates and adds the customer bubble layer. also defines a custom info window 
//to be displayed when clicking on a bubble.
function addCustomersLayer(map) {
    //Creates three types of Marker styles to represent the customers in different
    //state.
    var defaultFill = '#ff9999';
    var defaultSize = 20;

    //This style is for normal rendering of the customers
    var circleMarker = new OM.style.Marker(
            {
                width: defaultSize,
                height: defaultSize,
                lengthUnit: 'pixel',
                vectorDef: [{
                        shape: {type: "circle", cx: 0, cy: 0},
                        style: {fill: defaultFill, fillOpacity: 0.80, stroke: '#9baca6', strokeThickness: 1.5}
                    }
                ]
            });

    //This style is for rendering customers under mosue hover
    var hover = new OM.style.Marker(
            {
                width: defaultSize,
                height: defaultSize,
                lengthUnit: 'pixel',
                vectorDef: [{
                        shape: {type: "circle", cx: 0, cy: 0},
                        style: {fill: defaultFill, fillOpacity: 0.80, stroke: "#feeec2", strokeThickness: 1.5}
                    }
                ]
            });

    //This style is for customers that have been selected
    var select = new OM.style.Marker(
            {
                width: defaultSize,
                height: defaultSize,
                lengthUnit: 'pixel',
                vectorDef: [{
                        shape: {type: "circle", cx: 0, cy: 0},
                        style: {fill: defaultFill, fillOpacity: 0.80, stroke: "#462c22", strokeThickness: 1.5}
                    }
                ]
            });

    //The measure column that holds the sales data.
    var measureColumn = new OM.Column({
        data: salesData, //an array of <key, value> pairs loaded from sales.js
        keyGetter: function() {
            return this.name;  // the customer's name
        }, //'this' here always refers to an element of the data array.
        valueGetter: function() {
            return this.sales; // the sales to this customer
        },
    });

    //Now let's create a Size formatter that computes and
    //returns a marker size value (in pixels) for each possible data value in the Column.
    //You can also create a custom formatter, in which case you can use a
    //different algorithm to map the data values to marker sizes.
    var sizeFormatter = new OM.style.SizeFormatter({
        startingSize: 9,
        numClasses: 7,
        delta: 4,
        scale: 'linear'
    });

    //Finally, lets create the markers layer to display all the customers. 
    var customersLayer = new OM.layer.VectorLayer("customers",
            {
                def: {
                    type: OM.layer.VectorLayer.TYPE_DATAPACK,
                    url: "../u/data/customers.json"
                },

                //You can call customersLayer.setRenderingStyle(circle) later,
                //or just set it here as part of the layer definition. 
                renderingStyle: circleMarker,

                boundingTheme: true
            }
    );

    customersLayer.setSelectStyle(select);
    customersLayer.setHoverStyle(hover);

    //This is where everything is tied together.
    //It basically binds the measureColumn to the 'Size' aspect
    //of the circle markers. In other words the data values in the
    //measureColumn will drive the sizes of the markers.
    circleMarker.bindData('Size', measureColumn, sizeFormatter);

    //now bind the same data to the hover and select styles as well:
    hover.bindData('Size', measureColumn, sizeFormatter);
    select.bindData('Size', measureColumn, sizeFormatter);

    //next, we want to display the bubbles in different colors based
    //on who the customer's account manager is.
    var managerColors = ['#e7298a', '#7570b3', '#d95f02', '#1b9e77'];
    

    //Creates a new custom color formatter class by extending the OM.style.ColorFormatter
    //class and overriding its resolve() function.  
    //Such a custom formatter gives us full control on
    //how the values (account manager names) are mapped to colors.
    //The resolve method is called on every feature being displayed on the map.
    //The first parameter is the value of the current feature as obtained
    //from the data column. The second parameter references
    //the Column instance itself, which is not used in this particular case.   
    //The third parameter is the feature itself, again not used here.
    var _ColorFormatter = OM.style.ColorFormatter.extend({
        resolve: function(value, column)
        {
            if (!value) {
                return '#000000';  //black if no manager is found for a customer
            }
            
          if (value === 'alex') {
                return this.baseColors[0]; //#ff0000
            } else if (value === 'george') {
                return this.baseColors[1];
            } else if (value === 'max') {
                return this.baseColors[2];
            } else if (value === 'stacy') {
                return this.baseColors[3];
            } 
            
            return '#000000';
        }
    });

    //Creates a concrete instance of the extended class. The options
    //passed into the constructor are the same as the
    //base OM.style.ColorFormatter class.
    var colorFormatter = new _ColorFormatter({
        style: circleMarker, //optional, tells the formatter which style it will be affecting
        colors: managerColors, //a 4-color series for the 4 account managers in the customers data set.
        scale: 'log' //will be ignored since we implemented our own resolve() function
    });

    //bind the custom color formatter to the marker style and the 
    //attribute column 'account_mgr'. Note in this case we are not
    //creating a separate data wrapper OM.Column instance, instead we
    //can simply specify the property name since its already part of 
    //the vector layer's features.
    circleMarker.bindData('Fill', 'account_mgr', colorFormatter);
    hover.bindData('Fill', 'account_mgr', colorFormatter);
    select.bindData('Fill', 'account_mgr', colorFormatter);

    //setup a custom info window to be displayed when clicking on a feature of this layer
    setInfoWindow(map, customersLayer, [measureColumn]);

    //that's it. 
    map.addLayer(customersLayer);
}

//This function creates and displays a custom info window when clicking on a marker.
//Because the default info-window only shows properties that are already part of a 
//vector layer's features, it means the measure (sales) values will not be displayed
//in the default info-window, since they are obtained separately and not an intrinsic
//part of the features in the datapack. Here we show how to simulate the
//default info window while adding the external data value to it in the process. Note 
//that you can easily customize it further to give the info-window more 'personality'
//or better fit your application's overall theme.
function setInfoWindow(map, layer, columns)
    {
        if(!layer)
            return;
        
        //Disables the default info-window which shows only native properties already
        //defined in the datapack layer.
        layer.enableInfoWindow(false);
        
        //Creates a new click listener to be registered on the layer. 
        var clickListener = function(evt) 
        {
            //the evt object contains the current feature being clicked on                          
            var feature = evt.feature;

            //feature.attributes contains all the native properties of the feature
            //as defined in the original geoJson file.
            var attrs = feature.attributes;

            //current mouse pointer location
            var point = map.getCursorLocation();

            //Options for customizing the info-window's look and feel.
            //not used here as we will stick to the default info-window 'style'.
            var options={};

            var j=0;
            var html = "";
            
            //first, lets add all the existing properties of the feature to
            //the info-window. These property names and values are formatted 
            //into a simple html table.
            for(var attrName in attrs)
            {
              var value = attrs[attrName];

              if (value) 
              {
                var isNumeric = OM.util.ValidationUtil.isNumber(value);
                if(isNumeric)
                {
                    //remove trailing 0
                    value = parseFloat(value);  
                }
                else if(typeof value === 'string') 
                {
                    //clean up string values
                    value = value.replace(/\s/g,"&nbsp;");
                }
              }
              else
                continue;

              //alternating table row colors
              var color = (j % 2 === 0)? "#dddddd" :  "#bbbbbb";
              j++;

              //Add only non-label properties to the html table. _LABEL_ is a special property name
              //in geoJson files generated by MapViewer to represent a default label text property.
              if (attrName!=="_LABEL_")
                html += "<tr bgcolor='"+color+"'><td align='right'>"+attrName+"</td><td align='left'>"+value+"</td></tr>";
            }

            //The feature id will be used to obtain the external data values stored in the associated 
            //Column instances.            
            var geokey = feature.id;            

            //Obtain and add data values from the associated columns for the current feature
            //to the info-window table.
            for(var i=0; i<columns.length; i++)
            {
              //Use the Column instance's built-in method _getValueOfRow()_ to
              //obtain the data value for the given key.
              var measure = columns[i].getValueOfRow(geokey);    
              var measureName = columns[i].getMeasureName();
              if(!measure)
                  measure = "";                        
              color =  (j % 2 === 0)? "#dddddd" :  "#bbbbbb";
              html += "<tr bgcolor='"+color+"'><td align='right'>"+measureName+"</td><td align='left'>"+measure+"</td></tr>";
              j++;
            }
            
            //wrap all the properties into a table
            html = "<table style='margin:auto'>" + html + "</table>";
            
            //Now display the info-window on the map at the mouse pointer location.
            //Note that the second parameter can be an arbitrary HTML string.
            map.displayInfoWindow(point, html, options);                   
          };
          
          //finally, registers the click listener on the layer. Clicking on any feature 
          //of this layer will trigger it.
          layer.addListener(OM.event.MouseEvent.MOUSE_CLICK, clickListener);
    };
    
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
              title:"  Sales Distribution Map",
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