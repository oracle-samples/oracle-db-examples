-- example of using CTX_DOC.POLICY_LANGUAGES to detect language of a text

set serveroutput on

-- first create an Oracle Text policy using AUTO_LEXER

begin ctx_ddl.drop_preference('mylexer'); exception when others then null; end;
/

begin
  ctx_ddl.create_preference(
     preference_name => 'mylexer',
     object_name     => 'AUTO_LEXER'
  );
end;
/

begin ctx_ddl.drop_policy('mypolicy'); exception when others then null; end;
/

begin
  ctx_ddl.create_policy(
    policy_name =>  'mypolicy',
    lexer       =>  'mylexer');
end;
/

-- Now a PL/SQL block to detect the language of a text and list the possibilities.
-- Note there is also an option to write the results into a database table rather than an in-memory index-by table.
-- that option is not covered here.

declare
  outlist ctx_doc.language_tab;
  tab_size number;

  mytext varchar2(4000);

begin

  -- mytext := 'the quick brown fox jumps over the lazy dog';
  
  mytext := '
Je m''appelle Marie. Ma famille se compose de quatre personnes. Mon mari et moi avons deux enfants, une fille de sept ans et un garçon de trois ans. Nous avons également des animaux : un chat, un chien, deux lapins et des poissons rouges. Nous vivons dans une jolie maison avec un grand jardin. Notre quartier est calme et paisible. Je suis secrétaire et je m’occupe de mes deux enfants quand ils rentrent de l''école. Mon mari est professeur d’anglais dans une école qui se trouve à 20 kilomètres de la maison. Le dimanche, nous aimons nous promener en famille dans la forêt proche de notre maison et faire des jeux. Nous jouons dans le jardin quand il fait beau ou dans la maison quand il pleut.';

  -- detect languages
  ctx_doc.policy_languages (
     policy_name => 'mypolicy',
     document    => mytext,
     restab      => outlist 
  );

  -- list the non-zero entries
  if outlist.last is not null then
    for i in 1..outlist.last loop
      if outlist(i).score > 0 then
        dbms_output.put_line('Score: '|| outlist(i).score || ' Language: ' || outlist(i).language );
      end if;
    end loop;
  else 
    dbms_output.put_line ('empty list');
  end if;
end;
/

