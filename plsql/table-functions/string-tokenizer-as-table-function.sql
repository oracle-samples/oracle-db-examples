/*
This is a PL/SQL implementation to tokenize a string, based on a delimiter c
haracter, into a set of "tokens". Two tokenizers are being provided: 
One for VARCHAR2, one for CLOB. Both can be used procedurally in a 
PL/SQL loop or in SQL as a table function.

Created by Carsten Czarski
*/

-- Create type to describe a table row
-- This type describes a row of the String Tokenizers' result table.
create type token_t as object(  
  token_text varchar2(4000),  
  start_pos  number,  
  length     number  
) 
/

-- Create a table type to describe the result set
create type token_list as table of token_t 
/

-- CLOB Tokenizer: Type definition
/*
The String tokenizer is being implemented as two object types. One is for 
tokenizing CLOBs, the other one for tokenizing VARCHAR2s. The functionality is 
contained in its static and member functions. The types can be used procedurally 
or as a SQL table function.
*/

create type clob_tokenizer as object(  
  value_string       clob,  
  delimiter          varchar2(10),  
  parser_current_pos number,  
  last_token         varchar2(4000),  
  constructor function clob_tokenizer (p_string in clob, p_delim in varchar2) 
     return self as result,  
  member function has_more_tokens return number,  
  member function next_token(self in out nocopy clob_tokenizer) return varchar2,  
  static function all_tokens (p_string in clob, p_delim in varchar2) 
     return token_list pipelined parallel_enable,  
  static function all_tokens_cur (p_cursor in sys_refcursor, p_delim in varchar2) 
     return token_list pipelined parallel_enable (partition p_cursor by any)  
); 
/

-- CLOB tokenizer type implementation
-- The type body contains the actual implementations for the static and member procedures.
create or replace type body clob_tokenizer is  
  constructor function clob_tokenizer (p_string in clob, p_delim in varchar2) return self as result as  
  begin  
    self.value_string := p_string;  
    self.delimiter := p_delim;  
    self.parser_current_pos := 1;  
    self.last_token := null;  
    return ;  
  end;  
      
  member function has_more_tokens return number as  
  begin  
    if self.parser_current_pos <= dbms_lob.getlength(value_string) then   
      return 1;  
    else   
      return 0;  
    end if;  
  end;  
  
  member function next_token(self in out nocopy clob_tokenizer) return varchar2 is  
    l_next_delim_pos   number;  
    l_token            varchar2(4000);  
  begin  
    if self.has_more_tokens() = 1 then   
      l_next_delim_pos := dbms_lob.instr(self.value_string, self.delimiter, self.parser_current_pos);  
      if l_next_delim_pos = 0 then  
        l_token := dbms_lob.substr(  
          lob_loc => self.value_string,   
          amount  => (dbms_lob.getlength(self.value_string) - self.parser_current_pos) + 1,    
          offset  => self.parser_current_pos  
        );  
        parser_current_pos := dbms_lob.getlength(self.value_string) + 1;   
      else   
        l_token := dbms_lob.substr(  
          lob_loc => self.value_string,   
          amount  => l_next_delim_pos  - self.parser_current_pos,   
          offset  => self.parser_current_pos  
        );  
        parser_current_pos := l_next_delim_pos + length(self.delimiter);  
      end if;  
    else   
      l_token := null;  
    end if;  
    self.last_token := l_token;  
    return l_token;  
  end;  
  
  static function all_tokens (p_string in clob, p_delim in varchar2) 
       return token_list pipelined parallel_enable is  
    l_st clob_tokenizer := clob_tokenizer(p_string, p_delim);  
    l_startpos number;  
    l_token    varchar2(4000);  
  begin  
    while l_st.has_more_tokens = 1 loop  
      l_startpos := l_st.parser_current_pos;  
      l_token := l_st.next_token();  
      pipe row (token_t(l_token, l_startpos, nvl(length(l_token),0)));  
    end loop;  
    return;  
  end;  
  
  static function all_tokens_cur (p_cursor in sys_refcursor, p_delim in varchar2) 
        return token_list pipelined parallel_enable (partition p_cursor by any) is  
    l_st       clob_tokenizer;  
    l_string   clob;  
    l_startpos number;  
    l_token    varchar2(4000);  
  begin  
    loop  
      fetch p_cursor into l_string;    
      exit when p_cursor%notfound;  
       
      l_st := clob_tokenizer(l_string, p_delim);  
      while l_st.has_more_tokens = 1 loop  
        l_startpos := l_st.parser_current_pos;  
        l_token := l_st.next_token();  
        pipe row (token_t(l_token, l_startpos, nvl(length(l_token),0)));  
      end loop;  
    end loop;  
    return;  
  end;  
  
end; 
/

-- VARCHAR2 Tokenizer: Type definition
/*
The String tokenizer is being implemented as two object types. One is for 
tokenizing CLOBs, the other one for tokenizing VARCHAR2s. The functionality is 
contained in its static and member functions. The types can be used procedurally 
or as a SQL table function.
*/

create type string_tokenizer as object(  
  value_string       varchar2(4000),  
  delimiter          varchar2(10),  
  parser_current_pos number,  
  last_token         varchar2(4000),  
  constructor function string_tokenizer (p_string in varchar2, p_delim in varchar2) 
     return self as result,  
  member function has_more_tokens(self in out nocopy string_tokenizer) return number,  
  member function next_token(self in out nocopy string_tokenizer) return varchar2,  
  static function all_tokens (p_string in varchar2, p_delim in varchar2) 
     return token_list pipelined parallel_enable,  
  static function all_tokens_cur (p_cursor in sys_refcursor, p_delim in varchar2) 
     return token_list pipelined parallel_enable (partition p_cursor by any)  
); 
/

-- VARCHAR2 tokenizer type implementation
-- The type body contains the actual implementations for the static and member procedures.
create or replace type body string_tokenizer is  
  constructor function string_tokenizer (p_string in varchar2, p_delim in varchar2) 
     return self as result as  
  begin  
    self.value_string := p_string;  
    self.delimiter := p_delim;  
    self.parser_current_pos := 1;  
    self.last_token := null;  
    return ;  
  end;  
      
  member function has_more_tokens(self in out nocopy string_tokenizer) return number as  
  begin  
    if self.parser_current_pos <= length(value_string) then   
      return 1;  
    else   
      return 0;  
    end if;  
  end;  
  
  member function next_token(self in out nocopy string_tokenizer) return varchar2 as  
    l_next_delim_pos   number;  
    l_next_enclose_pos number;  
    l_token            varchar2(4000);  
  begin  
    if self.has_more_tokens() = 1 then   
      l_next_delim_pos := instr(self.value_string, self.delimiter, self.parser_current_pos);  
      if l_next_delim_pos = 0 then  
        l_token := substr(value_string, self.parser_current_pos);  
        parser_current_pos := length(self.value_string) + 1;   
      else   
        l_token := substr(self.value_string, self.parser_current_pos, 
                             l_next_delim_pos  - self.parser_current_pos);  
        parser_current_pos := l_next_delim_pos + length(self.delimiter);  
      end if;  
    else   
      l_token := null;  
    end if;  
    self.last_token := l_token;  
    return l_token;  
  end;  
  
  static function all_tokens (p_string in varchar2, p_delim in varchar2) 
       return token_list pipelined parallel_enable is  
    l_st string_tokenizer := string_tokenizer(p_string, p_delim);  
    l_startpos number;  
    l_token    varchar2(4000);  
  begin  
    while l_st.has_more_tokens = 1 loop  
      l_startpos := l_st.parser_current_pos;  
      l_token := l_st.next_token();  
      pipe row (token_t(l_token, l_startpos, nvl(length(l_token),0)));  
    end loop;  
    return;  
  end;  
  
  static function all_tokens_cur (p_cursor in sys_refcursor, p_delim in varchar2) 
        return token_list pipelined parallel_enable (partition p_cursor by any) is  
    l_st       string_tokenizer;  
    l_string   varchar2(4000);  
    l_startpos number;  
    l_token    varchar2(4000);  
  begin  
    loop  
      fetch p_cursor into l_string;    
      exit when p_cursor%notfound;  
       
      l_st := string_tokenizer(l_string, p_delim);  
      while l_st.has_more_tokens = 1 loop  
        l_startpos := l_st.parser_current_pos;  
        l_token := l_st.next_token();  
        pipe row (token_t(l_token, l_startpos, nvl(length(l_token),0)));  
      end loop;  
    end loop;  
    return;  
  end;  
end; 
/

-- Using STRING_TOKENIZER as table function.
-- This is the table function example for STRING_TOKENIZER. It tokenized a string with " " as the delimiter.
select rownum, token_text, start_pos, length  
from table(string_tokenizer.all_tokens('The quick brown fox jumps over the lazy dog.', ' ') ) ;

-- Using STRING_TOKENIZER as table function
-- This is the table function example for STRING_TOKENIZER. It tokenized a string with "#" as the delimiter.
select rownum, token_text, start_pos, length 
from table(string_tokenizer.all_tokens('##a#b#c#d#e#f##', '#') ) ;

-- Procedural use of STRING_TOKENIZER
-- This example uses the STRING_TOKENIZER within a PLSQL WHILE loop. The loop is 
-- running until HAS_MORE_TOKENS() returns zero and NEXT_TOKEN() returns the next token in the string.
create or replace procedure st_tester (p_string in varchar2, p_delim in varchar2) is 
  v_st string_tokenizer := string_tokenizer(p_string, p_delim); 
  v_cnt pls_integer := 0; 
begin 
  while v_st.has_more_tokens() = 1 loop 
    dbms_output.put_line(v_cnt||': '||v_st.next_token()); 
    v_cnt := v_cnt + 1; 
  end loop; 
end; 
/

-- Procedural use of STRING_TOKENIZER
-- This example uses the STRING_TOKENIZER within a PLSQL WHILE loop. The loop is 
-- running until HAS_MORE_TOKENS() returns zero and NEXT_TOKEN() returns the next token in the string.
begin 
  st_tester('The quick brown fox jumps over the lazy dog.', ' '); 
end;
/

