exec ctx_ddl.drop_preference  ('shoe_lx')
exec ctx_ddl.create_preference('shoe_lx', 'AUTO_LEXER')

drop index shoesindex;
create index shoesindex on shoe_reviews (review_text)
indextype is ctxsys.context
parameters('lexer shoe_lx')
parallel 4;

