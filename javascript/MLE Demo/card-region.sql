select title,
       subtitle,
       thumbnail as imageLinks
  from json_table( query(:P1_SEARCH), '$[*]'
        columns(
            title       varchar2(100)          path '$.title',
            subtitle       varchar2(100)   path '$.subtitle',
            thumbnail  VARCHAR2(4000) path '$.imageLinks.thumbnail'
        ) ); 