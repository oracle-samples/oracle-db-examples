--==============================================================================
type t_summary is record(
    page          number,
    total_results number,
    total_pages   number );

--==============================================================================
-- this function extracts result set information from the response JSON received
-- from the "themoviedb.org" REST API. Each JSON response contains information
-- about the total amount of pages, the page returned and the total amount of 
-- results.
--
-- {"page":1,"total_results":84,"total_pages":5,"results":[{ ... }]}
--==============================================================================
function get_summary( p_response clob ) return t_summary 
is
    l_summary t_summary;
begin
    select page,
           total_results,
           total_pages
      into l_summary.page,
           l_summary.total_results,
           l_summary.total_pages
      from json_table( p_response,
                       '$'
                       columns ( 
                           page          number path '$.page',
                           total_results number path '$.total_results',
                           total_pages   number path '$.total_pages' ) );
    return l_summary;
end get_summary;

--==============================================================================
-- REST Source Capabilities Procedure
--
-- This procedure tells APEX whether the Plug-In (and the REST API) supports
-- pagination (large result sets come as multiple pages), server-side filtering
-- and server-side ordering. 
--
-- The procedure implementation simply sets the "filtering", "pagination" or
-- "order_by" members of the apex_plugin.t_web_source_capabilities record type
-- to either true or false.
--
-- This plug-in supports the "themoviedb.org" pagination logic. Server Side 
-- filtering or ordering are not supported.
--==============================================================================
procedure capabilities_themoviedb (
    p_plugin         in            apex_plugin.t_plugin,
    p_result         in out nocopy apex_plugin.t_web_source_capabilities )
is
begin
    p_result.filtering            := false;
    p_result.pagination           := true;
    p_result.order_by             := false;
end capabilities_themoviedb;

--==============================================================================
-- REST Source Discovery Procedure
--
-- This procedure is called by APEX during the REST Data Source creation, when 
-- the "Discover" button is clicked. This procedure can:
-- * return structured information about the columns, data types and 
--   JSON or XML selectors
-- * return a JSON example which APEX then will sample to derive columns and
--   data types
--==============================================================================
procedure discover_themoviedb (
    p_plugin         in            wwv_flow_plugin_api.t_plugin,
    p_web_source     in            wwv_flow_plugin_api.t_web_source,
    p_params         in            wwv_flow_plugin_api.t_web_source_discover_params,
    p_result         in out nocopy wwv_flow_plugin_api.t_web_source_discover_result )
is
    l_web_source_operation          apex_plugin.t_web_source_operation;
    l_dummy_parameters              apex_plugin.t_web_source_parameters;
    l_in_parameters                 apex_plugin.t_web_source_parameters;
    l_time_budget                   number;

    l_param_idx                     pls_integer;
    
    c_query_param_name     constant varchar2(5)   := 'query';
    -- the default query to perform discovery is "star trek"
    l_query_param_value             varchar2(255) := 'star trek';
    l_has_query_param               boolean       := false;
begin
    --
    -- discovery is based on the "fetch rows" operation of a REST Data Source; this is typically
    -- a GET operation. POST is also possible, but that must be configured in Shared Components
    -- REST Data Sources, Operations, Fetch Rows.
    --
    -- This gets all meta data on the REST Operation as an instance of APEX_PLUGIN.T_WEB_SOURCE_OPERATION.
    -- The P_PERFORM_INIT parameter determines whether APEX should compute the URL and initialize all 
    -- HTTP Headers and parameters with their default values. The "l_web_source_operation" represents
    -- all attributes of the HTTP operation to be made.
    -- 
    l_web_source_operation := apex_plugin_util.get_web_source_operation(
        p_web_source   => p_web_source,
        p_db_operation => apex_plugin.c_db_operation_fetch_rows,
        p_perform_init => true );

    --
    -- This section copies the parameters, which we receive from the Create REST data source
    -- wizard, to the "l_in_parameters" array. If a "query" parameter has been defined, we'll
    -- memorize the value and we'll use the default if no value was provided.
    -- 
    for i in 1 .. l_web_source_operation.parameters.count loop
        l_in_parameters( l_in_parameters.count + 1 ) := l_web_source_operation.parameters( i );
        if l_web_source_operation.parameters( i ).name = c_query_param_name then
            l_query_param_value := nvl( l_web_source_operation.parameters( i ).value, l_query_param_value );
            l_has_query_param   := true;
        end if;
    end loop;

    --
    -- if the "query" parameter was provided by the developer, add it.
    --
    if not l_has_query_param then
        l_param_idx := l_in_parameters.count + 1;
        l_in_parameters( l_param_idx ).name       := c_query_param_name;
        l_in_parameters( l_param_idx ).param_type := wwv_flow_plugin_api.c_web_src_param_query;
    end if;

    --
    -- adjust the query string attribute of the REST operation to use the computed query parameter
    --
    l_web_source_operation.query_string := c_query_param_name || '=' || sys.utl_url.escape( l_query_param_value );

    --
    -- perform the REST request. We'll receive the JSON response in the "p_result.sample_response" 
    -- variable.
    --
    apex_plugin_util.make_rest_request(
        p_web_source_operation => l_web_source_operation,
        p_bypass_cache         => false,
        --
        p_time_budget          => l_time_budget,
        --
        p_response             => p_result.sample_response,
        p_response_parameters  => l_dummy_parameters );

    -- set the response headers received by the REST API for display in the Discovery Results screen
    p_result.response_headers      := apex_web_service.g_headers;
    -- "api.themoviedb.org" uses a fixed page size of 20 results
    p_result.fixed_page_size       := 20;
    -- the "query" parameter can also be used for "row searches" (see REST Data Source Parameters)
    p_result.row_search_param_name := 'query';
    -- Computed Parameters to pass back to APEX
    p_result.parameters            := l_in_parameters;
end discover_themoviedb;

--==============================================================================
-- REST Source Fetch Procedure
--
-- This procedure does the actual "Fetch" operation when rows are being 
-- requested from the REST Data Source. When an APEX component is about to
-- render, APEX computes the first row and the amount of rows required. This
-- and all dynamic filter and order by information is passed to the 
-- procedure as the "p_params" parameter. 
--==============================================================================
procedure fetch_themoviedb (
    p_plugin     in            apex_plugin.t_plugin,
    p_web_source in            apex_plugin.t_web_source,
    p_params     in            apex_plugin.t_web_source_fetch_params,
    p_result     in out nocopy apex_plugin.t_web_source_fetch_result )
is
    l_web_source_operation apex_plugin.t_web_source_operation;

    l_time_budget          number;
    l_summary              t_summary;
    l_page_id              pls_integer;
    l_start_page_id        pls_integer;
    l_continue_fetching    boolean     := true;
    l_page_to_fetch        pls_integer := 0;

    c_page_size            pls_integer := coalesce( p_params.fixed_page_size, 20 );

    l_query_string         varchar2(32767);
begin
    --
    -- This gets all meta data on the REST Operation as an instance of APEX_PLUGIN.T_WEB_SOURCE_OPERATION.
    -- The P_PERFORM_INIT parameter determines whether APEX should compute the URL and initialize all 
    -- HTTP Headers and parameters with their default values, from the REST Data Source configuration.
    -- The "l_web_source_operation" thus represents all attributes of the HTTP operation to be made.
    -- 
    l_web_source_operation := apex_plugin_util.get_web_source_operation(
        p_web_source   => p_web_source,
        p_db_operation => apex_plugin.c_db_operation_fetch_rows,
        p_perform_init => true );

    -- Initialize the response output. An invocation of the "Fetch" procedure can also return multiple
    -- JSON or XML documents, so responses are maintained as an instance of the APEX_T_CLOB (array of CLOB) type
    p_result.responses := apex_t_clob();

    -- compute the first page to be fetched, based on the "first" row information which we receive
    -- from APEX. The page size is contained in the "fixed_page_size" attribute of "p_params". Discovery
    -- sets this to 20. For the case that developers clear this value in REST Data Source operation settings,
    -- we use "20" when NULL.
    l_start_page_id := case when p_params.fetch_all_rows then 1 else floor( ( p_params.first_row - 1 ) / c_page_size ) + 1 end;
    
    -- start fetching with the first page to be fetched
    l_page_id      := l_start_page_id;
    -- memorize the query string from default REST Data Source settings
    l_query_string := l_web_source_operation.query_string;
    
    --
    -- check whether the "query" parameter has a value. If not (empty query), we do not reach out to the
    -- REST API at all. For an empty query, api.themoviedb.org would return an error response; so it does
    -- not make any sense to perform the call. Instead, we simply return an empty JSON response ({}).
    --
    for i in 1 .. l_web_source_operation.parameters.count loop
        if l_web_source_operation.parameters( i ).name = 'query' and l_web_source_operation.parameters( i ).value is null then
            p_result.has_more_rows       := false;
            p_result.response_row_count  := 0;
            p_result.response_first_row  := 0;
            p_result.responses.extend( 1 );
            p_result.responses( 1 ) := to_clob( '{}');
            return;
        end if;
    end loop;

    --
    -- if we are fetching all rows, fetch until the time budget is exhausted
    --
    while l_continue_fetching and coalesce( l_time_budget, 1 ) > 0 loop

        -- add a new member to the array of CLOB responses
        p_result.responses.extend( 1 );
        l_page_to_fetch := l_page_to_fetch + 1;

        --
        -- build the query string by using the operation attribute and appending the page to fetch
        -- query string example is: "query=star%20trek&page=2"
        --
        l_web_source_operation.query_string := l_query_string || 'page=' || l_page_id ;

        --
        -- perform the REST request. We'll receive the JSON response in the "p_result.sample_response" 
        -- variable. 
        --
        apex_plugin_util.make_rest_request(
            p_web_source_operation => l_web_source_operation,
            p_bypass_cache         => false,
            --
            p_time_budget          => l_time_budget,
            --
            p_response             => p_result.responses( l_page_to_fetch ),
            p_response_parameters  => p_result.out_parameters );

        --
        -- call "get_summary" in order to retrieve the total amount of pages and the total amount
        -- of results, so that we know whether there are more pages ot not.
        --
        l_summary := get_summary( p_result.responses( l_page_to_fetch ) );

        --
        -- if APEX requested "all rows" from the REST API and there are more rows to fetch,
        -- then continue fetching the next page 
        --
        l_continue_fetching := p_params.fetch_all_rows and l_summary.page < l_summary.total_pages;

        -- increase the page ID counter
        if l_continue_fetching then
            l_page_id := l_page_id + 1;
        end if;
    end loop;

    --
    if p_params.fetch_all_rows then
        
        -- if APEX requested (and our logic fetched) all rows, then there are no more rows to fetch
        p_result.has_more_rows       := false;
        -- the JSON responses contains the total amount of rows
        p_result.response_row_count  := l_summary.total_results;
        -- the first row in the JSON responses is "1"
        p_result.response_first_row  := 1;
    else
        -- APEX did _not_ request all rows, so there might be another page. If the current page number is
        -- below the amount of total pages, then there are more rows to fetch
        p_result.has_more_rows       := l_summary.page < l_summary.total_pages;
        
        -- The JSON responses contain 20 rows (fixed page size) if there are more pages to fetch. If 
        -- we fetched the last page, we need to compute the amount of rows on that page.
        p_result.response_row_count  := case when l_summary.page < l_summary.total_pages 
                                            then c_page_size 
                                            else l_summary.total_results - ( ( l_summary.page - 1 ) * c_page_size )
                                        end;

        -- the first row in the JSON response depends on the page we started fetching with. 
        p_result.response_first_row  := ( l_start_page_id - 1 ) * c_page_size + 1;
    end if;
end fetch_themoviedb;
