drop table library_stock
/
create table library_stock( book_info varchar2(2000) )
/

insert into library_stock values( '<author>John Irving</author> <stock>5</stock>' )
/
insert into library_stock values( '<author>Irving P. Irving</author> <stock>2</stock>' )
/


exec ctx_ddl.drop_section_group  ( 'my_sg' )
exec ctx_ddl.create_section_group( 'my_sg', 'BASIC_SECTION_GROUP' )
exec ctx_ddl.add_field_section   ( 'my_sg', 'author', 'author' )
exec ctx_ddl.add_sdata_section   ( 'my_sg', 'stock', 'stock', 'number' )

create index ls_ind on library_stock( book_info )
indextype is ctxsys.context
parameters( 'section group my_sg' )
/

select book_info, score(1) from library_stock
where contains (book_info, '
<query>
  <textquery>
    irving within author and sdata(stock > 1) 
  </textquery>
  <score normalization_expr = "sdata(stock)"/>
</query>
', 1) > 0 order by score(1) desc
/

