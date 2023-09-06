set heading off
whenever sqlerror continue;
set serveroutput on


PROMPT Creating PAvTranslate Function...
create or replace function PAvTranslate(
        query in varchar2 default null,
        section_flag in boolean default false,
        section1 in varchar2 default 'homepage',
        section2 in varchar2 default 'head'
        
        )
        return varchar2
as
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

  len := length(query);

  -- we iterate over the string to find special web operators
  for i in 1..len loop
    char := substr(query,i,1);
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
      token := '{'||substr(query,tokenStart,tokenFinish-tokenStart+1)||'}';      
      if(inPlus=1) then
        plusS := plusS||','||token||'*8';
        hasPlus :=1;    
      elsif(inMinus=1) then
        minusS := minusS||'OR '||token||' ';
        hasMinus :=1;
      else
        mainS := mainS||' NEAR '||token;
        mainAboutS := mainAboutS||' '||token; 
        hasMain :=1;
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
    token := '{'||substr(query,tokenStart,len-tokenStart+1)||'}';
    if(inPlus=1) then
      plusS := plusS||','||token||'*8';
      hasPlus :=1;      
    elsif(inMinus=1) then
      minusS := minusS||'OR '||token||' ';
      hasMinus :=1;
    else
      mainS := mainS||' NEAR '||token;
      mainAboutS := mainAboutS||' '||token; 
      hasMain :=1;
    end if;
  end if;
  
  mainS := substr(mainS,6,length(mainS)-5);
  mainAboutS := replace(mainAboutS,'{',' ');
  mainAboutS := replace(mainAboutS,'}',' ');
  mainAboutS := replace(mainAboutS,')',' ');
  mainAboutS := replace(mainAboutS,'(',' ');
  plusS := substr(plusS,2,length(plusS)-1);
  minusS := substr(minusS,4,length(minusS)-4);


dbms_output.put_line('mainS:'||mainS);
dbms_output.put_line('mainAboutS:'||mainAboutS);
dbms_output.put_line('plusS:'||plusS);
dbms_output.put_line('minusS:'||minusS);

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
