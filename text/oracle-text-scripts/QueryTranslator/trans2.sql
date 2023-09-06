set heading off
whenever sqlerror continue;
set serveroutput on


PROMPT Creating PAvTranslate Function...


-- Clean string: remove any illegal characters
-- Illegal characters are here defined as anything EXCEPT

--   Alphanumerics
--   PrintJoins (defined in a list - could fetch from database
--     if preferred)
--   "+" at the beginning of a word
--   "-" at the beginning of a word
--   "*" at the end of a word
--   Double quotes around a set of words

create or replace procedure cleanStr (str in out varchar2) is

begin

    str := regexp_replace (str, '([[:space:]]*([[:alnum:]]+)[[:space:]]*)+', '\2\3\4');



--   str := translate (str, '!"£$%^&*()_-=:@~;#<>?,./\|{}[]', 
--                           '                              ');
--  str := regexp_replace (str, '[[:space:]]+', ' ');
    dbms_output.put_line(str);
end;
/
show err

create or replace function PAvTranslate(
        query in varchar2 default null,
        section_flag in boolean default false,
        section1 in varchar2 default 'homepage',
        section2 in varchar2 default 'head'
        
        )
        return varchar2
as
        type wordInfo is record (
          text varchar2(64),
          required boolean,
          notAllowed boolean
        );

        type wordListType is table of varchar2(64);
        plussList       wordListType := wordListType();
        minusList       wordListType := wordListType();
        ordinList       wordListType := wordListType();

        qry             varchar2(32000);
        i               number := 0;
        len             number := 0;
        char            varchar2(1);
        minusS  varchar2(2000);
        plusS   varchar2(2000);
        mainS   varchar2(2000);
        mainPhraseS varchar2(2000);
        mainAccumS varchar2(2000);
        mainAboutS      varchar2(2000);
        finalS  varchar2(2000);
        hasMain         number := 0;
        hasPlus         number := 0;
        hasMinus        number := 0;
        token           varchar2(2000);
        tokenStart      number := 1;
        tokenFinish     number := 0;
        inPhrase        number := 0;
        inPlus          number := 0;
        inWord          number := 0;
        inMinus         number := 0;
        completePhrase  number := 0;
        completeWord    number := 0;
        code            number := 0;
begin

  qry := query;
  cleanStr(qry);
  len := length(qry);

  -- we iterate over the string to find special web operators
  for i in 1..len loop
    char := substr(qry,i,1);
    if((char = '"') or (char = ''''))then
      if(inPhrase = 0) then
        inPhrase := 1;
        tokenStart := i;
      else
        inPhrase := 0;
        completePhrase := 1;
        tokenFinish := i-1;
      end if;
    elsif(char = ' ') then
      if((inPhrase = 0) and (inword = 1)) then
        completeWord := 1;
        inword :=0;
        tokenFinish := i-1;
      end if;
    elsif(char = '+') then
      inPlus := 1;
      tokenStart := i+1;
    elsif((char = '-') and (i = tokenStart)) then
      inMinus :=1;
      tokenStart := i+1;
    else
      inword := 1;      
    end if;

    if((completeWord=1) and (tokenFinish>tokenStart)) then
      token := substr(qry,tokenStart,tokenFinish-tokenStart+1);      

      --cleanup(token);

      if(inPlus=1) then
        plussList.extend(1);
        plussList(plussList.last()) := token;
      elsif(inMinus=1) then
        minusList.extend(1);
        minusList(minusList.last()) := token;
      else
        ordinList.extend(1);
        ordinList(ordinList.last()) := token;
      end if;


      tokenStart  :=i+1;
      tokenFinish :=0;
      inPlus := 0;
      inMinus :=0;
    end if;
    completePhrase := 0;
    completeWord :=0;
  end loop;

  -- find the last token
  if (inword=1) then
    token := '{'||substr(qry,tokenStart,len-tokenStart+1)||'}';
    if(inPlus=1) then
      plussList.extend(1);
      plussList(plussList.last()) := token;
    elsif(inMinus=1) then
      minusList.extend(1);
      minusList(minusList.last()) := token;
    else
      ordinList.extend(1);
      ordinList(ordinList.last()) := token;
    end if;
  end if;
  
dbms_output.put_line('plussList: ');
if (plussList.count > 0) then
  for i in 1..plussList.last loop
    dbms_output.put_line(lpad(i, 3)||': '||plussList(i));
  end loop;
end if;

dbms_output.put_line('minusList: ');
if (minusList.count > 0) then
  for i in 1..minusList.last loop
    dbms_output.put_line(lpad(i, 3)||': '||minusList(i));
  end loop;
end if;

dbms_output.put_line('ordinList: ');
if (ordinList.count > 0) then
  for i in 1..ordinList.last loop
    dbms_output.put_line(lpad(i, 3)||': '||ordinList(i));
  end loop;
end if;


return ('');

  -- we find the components present and then process them based on the specific combinations
  code := hasMain*4+hasPlus*2+hasMinus;
  mainPhraseS := mainS;
  mainPhraseS := replace(mainPhraseS,' NEAR ',' ');
  mainAccumS :=  mainS;
  mainAccumS :=  replace(mainAccumS,' NEAR ',' , ');    
  if(code = 7) then
    finalS := '(('||plusS||'),'||'('||mainPhraseS||')*4,'||'('||mainS||')*2,'||'('||mainAccumS||')*1,'||'about('||mainAboutS||')*1)'||' NOT ('||minusS||')';
    plusS := replace(plusS,',',' AND ');
    finalS := '(('||plusS||')*10)*10 AND ('||finalS||')';
  elsif (code = 6) then  
    finalS :=  '('||plusS||'),'||'('||mainPhraseS||')*4,'||'('||mainS||')*2,'||'('||mainAccumS||')*1,'||'about('||mainAboutS||')*1';
    plusS := replace(plusS,',',' AND ');
    finalS := '(('||plusS||')*10)*10 AND ('||finalS||')';       
  elsif (code = 5) then
    finalS := '(('||mainPhraseS||')*4,'||'('||mainS||')*2,'||'('||mainAccumS||')*1,'||'about('||mainAboutS||')*1)'||' NOT ('||minusS||')';  
  elsif (code = 4) then  
    if (section_flag = TRUE) then
      finalS := '('||mainPhraseS||' within '||section1||')*6,'||'('||mainPhraseS||' within '||section2||')*2,'
                ||'('||mainPhraseS||')*1,'||'('||mainS||')*1,'||'('||mainAccumS||')*1,'||'about('||mainAboutS||')*1';
    else
      finalS := '('||mainPhraseS||')*3,'||'('||mainS||')*1,'||'('||mainAccumS||')*1,'||'about('||mainAboutS||')*1';
    end if;
  elsif (code = 3) then  
    finalS := '('||plusS||') NOT ('||minusS||')';
  elsif (code = 2) then  
    plusS := replace(plusS,',',' AND ');
    finalS :=  plusS; 
  elsif (code = 1) then  
    -- not is a binary operator for intermedia text
    finalS := 'is'||' NOT ('||minusS||')';
  elsif (code = 0) then  
    finalS := '';
  end if;

  return finalS;
end PAvTranslate;
/
show errors;


-- Cleanup a token, removing any illegal characters and 
--function cleanup(tkn in out varchar2) is


