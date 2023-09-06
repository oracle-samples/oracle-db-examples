create or replace function get_article_text (p_id number) return varchar2 is
  v_outbuff       varchar2(32767) := ' ';

  v_channel_id	  number; 
  v_status_id	  number; 
  v_headline	  varchar2(32767); 
  v_subheadline	  varchar2(32767);
  v_article_text  varchar2(32767); 
  v_byline		  varchar2(32767);
begin
  select channel_id, status_id, headline, subheadline, article_text, byline
  into v_channel_id, v_status_id, v_headline, v_subheadline, v_article_text, v_byline
  from articles
  where article_id = p_id;

  v_outbuff := v_outbuff || '<CHANNELID>'    || v_channel_id    || '</CHANNELID>';
  v_outbuff := v_outbuff || '<STATUSID>'    || v_status_id    || '</STATUSID>';
  v_outbuff := v_outbuff || '<HEADLINE>'    || v_headline     || '</HEADLINE>';
  v_outbuff := v_outbuff || '<SUBHEADLINE>' || v_subheadline  || '</SUBHEADLINE>';
  v_outbuff := v_outbuff || '<ARTICLETEXT>' || v_article_text || '</ARTICLETEXT>';
  v_outbuff := v_outbuff || '<BYLINE>'      || v_byline       || '</BYLINE>';  
  
  return v_outbuff;
  
end;
/

create or replace function get_recipe_text (p_id number) return varchar2 is
  v_outbuff       varchar2(32767) := ' ';

  v_status_id	  number; 
  v_name		  varchar2(32767); 
  v_recipe_text	  varchar2(32767);
  v_ingredients	  varchar2(32767); 
  v_method		  varchar2(32767);
begin
  select status_id, name, recipe_text, ingredients, method
  into v_status_id, v_name, v_recipe_text, v_ingredients, v_method
  from recipes
  where recipe_id = p_id;

  v_outbuff := v_outbuff || '<STATUSID>'    || v_status_id    || '</STATUSID>';
  v_outbuff := v_outbuff || '<RECIPETEXT>'  || v_recipe_text  || '</RECIPETEXT>';
  v_outbuff := v_outbuff || '<INGREDIENTS>' || v_ingredients  || '</INGREDIENTS>';
  v_outbuff := v_outbuff || '<METHOD>'      || v_method       || '</METHOD>';
  
  return v_outbuff;
  
end;
/
create or replace function get_tvlist_text (p_id number) return varchar2 is
  v_outbuff		  		    varchar2(32767) := ' ';

  v_channel_id	  			number; 
  v_tvlist_name	  		  	varchar2(32767); 
  v_tvlist_text	  			varchar2(32767); 
  v_tvlist_episode_name		varchar2(32767);
  v_tvlist_cast		  		varchar2(32767); 
  v_tvlist_pa_category		varchar2(32767);
  v_tvlist_film_director	varchar2(32767);
begin
  select tvlist_name, tvlist_text, tvlist_episode_name, tvlist_cast, tvlist_pa_category, tvlist_film_director
  into v_tvlist_name, v_tvlist_text, v_tvlist_episode_name, v_tvlist_cast, v_tvlist_pa_category, v_tvlist_film_director
  from tv_list
  where tvlist_id = p_id;

  v_outbuff := v_outbuff || '<TVNAME>'     || v_tvlist_name          || '</TVNAME>';
  v_outbuff := v_outbuff || '<TVTEXT>'     || v_tvlist_text          || '</TVTEXT>';
  v_outbuff := v_outbuff || '<TVEPISODE>'  || v_tvlist_episode_name  || '</TVEPISODE>';
  v_outbuff := v_outbuff || '<TVCAST>'     || v_tvlist_cast          || '</TVCAST>';
  v_outbuff := v_outbuff || '<TVCATEGORY>' || v_tvlist_pa_category   || '</TVCATEGORY';  
  v_outbuff := v_outbuff || '<TVDIRECTOR>' || v_tvlist_film_director || '</TVDIRECTOR>';
  
  return v_outbuff;
  
end;


/
create or replace procedure master_uds 
  (rid in rowid,
   tlob in out nocopy clob ) is

  v_source 	   		  	   varchar2(2);
  v_text_id				   number;
  v_length                 integer;
  v_buffer                 varchar2(32767);
  
  BEGIN
  -- Get the source and foreign key for this data item
  
  select source, text_id into v_source, v_text_id 
  from master_text_index where rowid = rid;
  
  if v_source = 'AR' then
    v_buffer := get_article_text(v_text_id);
  elsif v_source = 'RE' then
    v_buffer := get_recipe_text(v_text_id);
  else   -- v_source = 'TV'
    v_buffer := get_tvlist_text(v_text_id);
  end if;

  Dbms_Lob.Trim
    (
      lob_loc        => tlob,
      newlen         => 0
    );

  Dbms_Lob.Write
    (
      lob_loc        => tlob,
      amount         => length ( v_buffer ),
      offset         => 1,
      buffer         => v_buffer
    );
  
end;





