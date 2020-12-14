    var myuniv;
    var myconfig;
    var baseURL = location.protocol + "//" + location.host + "/mapviewer";
    function showMap() {
        var map = new OM.Map(
                document.getElementById('map'),
                {
                   mapviewerURL:baseURL,
                   disableOverviewMap:false
                });
                
        var tileLayer = new OM.layer.ElocationTileLayer("elocation", 
                          {
                            //"layerName": "WORLD_MAP"
                            "layerName": "BI_WORLD_MAP"
                            //"layerName": "BI_WORLD_MAP_LIGHT"
                         });
        map.addLayer(tileLayer) ;
        
        //addDTL_States(map);
        addDTL_Counties(map);
        addDTL_Cities(map);
          
        map.setMapCenter(new OM.geometry.Point(-100, 35, 8307));  // all
        map.setMapZoomLevel(3) ; // level 11 to test max_size_in_px
        
        map.init();
        addMapControls(map);
    }
    
    function addDTL_States(map) {
        //-------------------------------------------------
        // DTL1: states using jdbc theme
        // step 1: create styles and themes
        // step 1.1 create style
        var myc1 = new OM.style.Color({
            styleName: "mycolor1",
            stroke: "#000000", 
            strokeOpacity: 0.5,
            fill: "#F2EFE9", 
            fillOpacity: 0.0
        });

        // 
        // step 1.2: create themes (jdbc theme)
        var jdbcTStates= new OM.server.ServerJDBCTheme('theme_jdbc_states');
        jdbcTStates.setDataSourceName('mvdemo');
        jdbcTStates.setSRID('8307');
        jdbcTStates.setGeometryColumnName('geom');
        var sql='select totpop, poppsqmi, state, state_abrv, geom from states';
        jdbcTStates.setQuery(sql);
        jdbcTStates.addInfoColumn({column: 'state_abrv', name:'State'});
        jdbcTStates.addInfoColumn({column: 'totpop', name:'Population'});
        jdbcTStates.addInfoColumn({column: 'poppsqmi', name:'Pop. Density'});
        jdbcTStates.setRenderingStyleName('mycolor1');

        // Step 2: Create a server map request object; set its properties; and add themes and styles into it.
        // 2.1
        var req = new OM.server.ServerMapRequest(baseURL);
        // 2.2
        req.setProperties({
            dataSource:"MVDEMO",
            transparent:true,
            antialiase:"false"
        });       
        req.addTheme(jdbcTStates);
        req.addStyle(myc1);

        // Step 3: Create DTL required elements: universe, config, properties; create a DTL instance and add it into OM.Map object
        // 3.1 create universe, config, and dtl needed properties        
        myuniv= new OM.universe.WorldMercatorUniverse();
        myconfig=new OM.layer.TileLayerConfig(
                {
                    tileImageWidth: 256,  
                    tileImageHeight: 256
                });
        // for a DTL, the following properties precedes req's properties
        var dtl_props = {  // dtl specific properties
            //dataSource:"MVDEMO", // if not provided, it comes from ServerMapRequest;
            universe: myuniv,            
            tileLayerConfig: myconfig,
            tileServerURL: baseURL + "/omserver",  // required, if not provided, it will take ServerMapRequest's baseURL + '/omserver'
            enableUTFGrid: true,
            enableUTFGridInfoWindow: true,
            utfGridResolution: 4
        };
        // step 3.2: create a dtl instance and added into an OM.Map instance
        layerJDBCStates = new OM.layer.DynamicTileLayer("layerJDBCStates", dtl_props, req);        
        map.addLayer(layerJDBCStates);
    }
      
    function addDTL_Counties(map) {
        //-------------------------------------------------
        // DTL2: counties using jdbc theme
        // step 1: create styles and themes
        // step 1.1 create styles
        var sty1 = new OM.style.Color({
                    styleName: "myc1",stroke: "#B77640", strokeOpacity: 0.1, fill: "#FFE6B4", fillOpacity: 0.3
                });
        var sty2 = new OM.style.Color({
                    styleName: "myc2",stroke: "#B77640", strokeOpacity: 0.1,fill: "#EFBD81", fillOpacity: 0.5
                });
        var sty3 = new OM.style.Color({
                    styleName: "myc3",stroke: "#B77640", strokeOpacity: 0.1,fill: "#CB8347", fillOpacity: 0.6
                });
        var sty4 = new OM.style.Color({
                    styleName: "myc4",stroke: "#B77640", strokeOpacity: 0.1,fill: "#B41E00", fillOpacity: 0.7
                });
        var bkt1 = new OM.style.RangedBucket({seq:0,label: "0 - 50,000",low:0,high:50000});
        var bkt2 = new OM.style.RangedBucket({seq:1,label:"50,000 - 2.5K",low:50000,high:250000});
        var bkt3 = new OM.style.RangedBucket({seq:2,label:"2.5K - 7.5K",low:250000,high:7500000});
        var bkt4 = new OM.style.RangedBucket({seq:3,label:"&gt; 7.5K",low:7500000,high:99999999});
        /* -- for poppsqmi
        var bkt1 = new OM.style.RangedBucket({seq:0,low:0,high:100});
        var bkt2 = new OM.style.RangedBucket({seq:1,low:100,high:500});
        var bkt3 = new OM.style.RangedBucket({seq:2,low:500,high:2000});
        var bkt4 = new OM.style.RangedBucket({seq:3,low:2000,high:99999999});*/
        var bucketStyle = new OM.style.BucketStyle({
                    classification: "custom",
                    styleName: 'my_adv_buckets',
                    styles: [sty1, sty2, sty3, sty4],
                    buckets: [bkt1, bkt2, bkt3, bkt4],
                    numClasses: 4,
                    defaultStyle: sty2
                });

        // step 1.2: create jdbc theme
        var jdbcTCounties= new OM.server.ServerJDBCTheme('theme_jdbc_counties');
        jdbcTCounties.setDataSourceName('mvdemo');
        jdbcTCounties.setSRID('8307');
        jdbcTCounties.setGeometryColumnName('geom');
        var sql='select totpop, poppsqmi, county, state_abrv, geom from counties';
        jdbcTCounties.setQuery(sql);
        jdbcTCounties.addInfoColumn({column: 'state_abrv', name:'State'});
        jdbcTCounties.addInfoColumn({column: 'county', name:'County'});
        jdbcTCounties.addInfoColumn({column: 'totpop', name:'Population'});
        jdbcTCounties.addInfoColumn({column: 'poppsqmi', name:'Pop. Density'});
        jdbcTCounties.setRenderingStyleName('my_adv_buckets');
        //jdbcTCounties.setRenderingStyleValueColumns('poppsqmi'); // the column that is bound to the bucket style
        jdbcTCounties.setRenderingStyleValueColumns('totpop'); // the column that is bound to the bucket style

        // step 2 Create server map request instance; set its properties; and add themes and styles into it.
        // step 2.1 create server map request object
        var req1 = new OM.server.ServerMapRequest(baseURL);
        
        // step 2.2: set req properties 
        req1.setProperties({
            dataSource:"MVDEMO",
            transparent:true,
            antialiase:"false"
        });
        // step 2.3: add themes and styles into request
        req1.addTheme(jdbcTCounties);
        req1.addStyle(bucketStyle);               
        
        // for a DTL, the following properties precedes req's properties
        var dtl_props = {  // dtl specific properties
            //dataSource:"MVDEMO", // if not provided, it comes from ServerMapRequest;
            universe: myuniv,            
            tileLayerConfig: myconfig,
            tileServerURL: baseURL + "/omserver",  // required, if not provided, it will take ServerMapRequest's baseURL + '/omserver'
            enableUTFGrid: true,
            enableUTFGridInfoWindow: true,
            utfGridResolution: 4
        };
        // step 3: create DTL and add it into map obj
        var layerJDBCCounties = new OM.layer.DynamicTileLayer("layerJDBCCounties", dtl_props, req1);
        map.addLayer(layerJDBCCounties);
      
    }
    
    function addDTL_Cities(map) {
        //DTL 3: cities using jdbc theme
        // step 1: create styles and themes
        // step 1.1 create styles
        // scalable circle with size capped
        var m1 = new OM.style.Marker({
                    styleName: 'mym1',
                    width: 8,
                    height: 8,
                    lengthUnit: "pixel",
                    vectorDef: [{
                            shape: {type: "circle", x: 0, y:0, width:10, height:10},
                            style: {fill: "#FF9C87", fillOpacity:1,
                                    stroke: "#ffffff", strokeThickness:1}
                    }]
                });
        // test 2: scalable rectangle with size capped
        var m2 = new OM.style.Marker({
                    styleName: 'mym2',
                    width: 14,
                    height: 14,
                    lengthUnit: "pixel",
                    vectorDef: [{
                            shape: {type: "circle", cx: 0, cy: 0},
                            //style: {fill: "#979CA0", fillOpacity:0.7,
                            style: {fill: "#FFFF97", fillOpacity:0.7,
                                    stroke: "#ffffff", strokeThickness:1}
                    }]
                });
        // test 3: 
        var m3 = new OM.style.Marker({
                    styleName: 'mym3',
                    width: 18,
                    height: 18,
                    lengthUnit: "px",
                    vectorDef: [{
                            shape: {type: "circle", cx: 0, cy: 0},
                            style: {fill: "#A7ACB0", fillOpacity:0.7,
                                    stroke: "#ffffff", strokeThickness:1}
                    }]
                });
  
        var t1 = new OM.style.Text({
                styleName:"myt1",
                fill:"#000000",
                fontStyle: OM.Text.FONTSTYLE_NORMAL, // plain
                fontFamily:"Dialog",
                fontSize:10,
                hAlign:OM.Text.HORIZONTALALIGN_LEFT
            });

        var t2 = new OM.style.Text({
                styleName:"myt2",
                fill:"#000000",
                fontStyle: OM.Text.FONTSTYLE_NORMAL, // plain
                fontFamily:"Dialog",
                fontSize:12,
                hAlign:OM.Text.HORIZONTALALIGN_LEFT
            });

        var t3 = new OM.style.Text({
                styleName:"myt3",
                fill:"#111111",
                fontStyle: OM.Text.FONTSTYLE_NORMAL, // plain
                fontFamily:"Dialog",
                fontSize:14,
                hAlign:OM.Text.HORIZONTALALIGN_LEFT
            });

        // step 1.2: create jdbc theme
        var jdbcTCities_small= new OM.server.ServerJDBCTheme('theme_jdbc_cities_small');
        jdbcTCities_small.setDataSourceName('mvdemo');
        jdbcTCities_small.setSRID('8307');
        jdbcTCities_small.setGeometryColumnName('location');
        jdbcTCities_small.setLabelColumnName('city');
        jdbcTCities_small.setLabelStyleName('myt1');
        
        jdbcTCities_small.setQuery('select location, city, state_abrv, pop90, rank90 from cities_us where pop90 &lt; 250000');
        jdbcTCities_small.addInfoColumn({column: 'state_abrv', name:'State'});
        jdbcTCities_small.addInfoColumn({column: 'city', name:'City'});
        jdbcTCities_small.addInfoColumn({column: 'pop90', name:'Population'});
        jdbcTCities_small.addInfoColumn({column: 'rank90', name:'Rank'});
        jdbcTCities_small.setRenderingStyleName('mym1');
    
        var jdbcTCities_medium= new OM.server.ServerJDBCTheme('theme_jdbc_cities_medium');
        jdbcTCities_medium.setDataSourceName('mvdemo');
        jdbcTCities_medium.setSRID('8307');
        jdbcTCities_medium.setGeometryColumnName('location');
        jdbcTCities_medium.setLabelColumnName('city');
        jdbcTCities_medium.setLabelStyleName('myt2');
        
        jdbcTCities_medium.setQuery('select location, city, state_abrv, pop90, rank90 from cities_us where pop90 between 250000 and 500000');
        jdbcTCities_medium.addInfoColumn({column: 'state_abrv', name:'State'});
        jdbcTCities_medium.addInfoColumn({column: 'city', name:'City'});
        jdbcTCities_medium.addInfoColumn({column: 'pop90', name:'Population'});
        jdbcTCities_medium.addInfoColumn({column: 'rank90', name:'Rank'});
        jdbcTCities_medium.setRenderingStyleName('mym2');
        
        var jdbcTCities_big= new OM.server.ServerJDBCTheme('theme_jdbc_cities_big');
        jdbcTCities_big.setDataSourceName('mvdemo');
        jdbcTCities_big.setSRID('8307');
        jdbcTCities_big.setGeometryColumnName('location');
        jdbcTCities_big.setLabelColumnName('city');
        jdbcTCities_big.setLabelStyleName('myt3');
        
        jdbcTCities_big.setQuery('select location, city, state_abrv, pop90, rank90 from cities_us where pop90 &gt; 500000');
        jdbcTCities_big.addInfoColumn({column: 'state_abrv', name:'State'});
        jdbcTCities_big.addInfoColumn({column: 'city', name:'City'});
        jdbcTCities_big.addInfoColumn({column: 'pop90', name:'Population'});
        jdbcTCities_big.addInfoColumn({column: 'rank90', name:'Rank'});
        jdbcTCities_big.setRenderingStyleName('mym3');
        // 
        // step 2 Create server map request instance; set its properties; and add themes and styles into it.
        // step 2.1 create server map request object
        var req2 = new OM.server.ServerMapRequest(baseURL);
        
        // step 2.2: set req properties 
        req2.setProperties({
            dataSource:"MVDEMO",
            transparent:true,
            antialiase:"false"
        });
        // step 2.3: add themes and styles into req
        //req2.addThemes([jdbcTCities_small, jdbcTCities_medium, jdbcTCities_big]);  
        //req2.addStyles([m1, t1, t2, m2, t3, m3]);  // add all needed styles into request
        req2.addThemes([jdbcTCities_big]);  
        req2.addStyles([t3, m3]);  // add all needed styles into request

        //Step 3: Create DTL required elements: universe, config, properties; create a DTL instance and add it into OM.Map object
        // for dyn tile layer, the following properties are considered first (override what's in ServerMapRequest)
        var dtl_props2 = {  // those are dtl specific
            //dataSource:"MVDEMO", // if not provided, it comes from ServerMapRequest;
            universe: myuniv,            
            tileLayerConfig: myconfig,
            tileServerURL: baseURL + "/omserver",  // required, if not provided, it will take ServerMapReq's baseURL + '/omserver'
            enableUTFGrid: true,
            //enableUTFGridInfoWindow: false,
            utfGridResolution: 4
        }

        //create DTL and add it into map obj
        var layerJDBCCities = new OM.layer.DynamicTileLayer("layerJDBCCities", dtl_props2, req2);
        //two lines below are designated for testing
        layerJDBCCities.enableUTFGridInfoWindow(true);  // use function call to enable built-in infor window
        //layerJDBCStates.enableUTFGridInfoWindow(false);  // use function call to enable built-in infor window
        map.addLayer(layerJDBCCities) ;
    }

    function addMapControls(map) {
        addMapNavControl(map)
        addMapCopyright(map);
        addMapTitle(map);
        addMapScale(map);
        addToolBar(map);
    }
    
    
    function addMapTitle(map) {
      var maptitle = new OM.control.MapDecoration(null,
          { 
              anchorPosition: 2,
              title:"  Dynamic Tile Layer",
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
        var mapCopyRight = new OM.control.CopyRight({anchorPosition:5,
                                                     textValue:'Map data: <a href="https://www.naturalearthdata.com/" target="_blank"> Natural Earth </a>',
                                                     fontSize:12,fontFamily:'Arial',fontColor:'black'});
        map.addMapDecoration(mapCopyRight);
    }
    function addToolBar(map) {    
        var toolbar = new OM.control.ToolBar("toolbar1", 
          {
            builtInButtons : [OM.control.ToolBar.BUILTIN_ALL]
          });
        toolbar.setPosition(0.8,0.0);
        map.addToolBar(toolbar);
    }