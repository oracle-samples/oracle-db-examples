import java.sql.*;
import java.util.*;
import java.io.*;
import oracle.jdbc.*;
import oracle.sql.*;

public class KWIC {
    private static String opentag = "<i><b><font color=red>"; 
    private static String closetag = "</font></b></i>";
    private static String stoptag = "<applet>";
    private int closetag_len = 0;
    private int opentag_len = 0;
    private Vector terms = new Vector();
    private String myQuery = "";

    public KWIC()
    {
	opentag_len = opentag.length();
	closetag_len = closetag.length();
    }
    
    synchronized public void init(Connection conn, 
				  Vector queryTerms) 
	throws SQLException
    {
	conn.createStatement().execute("begin ctx_doc.set_key_type('rowid'); end; ");
	terms = queryTerms;

	// form the highlight query
	StringBuffer query = new StringBuffer("");
        int length = (terms == null) ? 0 : terms.size();
	for (int ii=0; ii < length; ii++)
	    {
		String str=(String)terms.elementAt(ii);
		if(ii>0)
		    {
			query.append("|");
		    }
		query.append("{");
		query.append(str);
		query.append("}");
	    }
	myQuery = query.toString();
    }

    synchronized public String getKWIC(Connection conn, String idxname, String key)
	throws IOException   
    {
	String ststr = "begin "+
        "ctx_doc.markup(index_name=>?,"+
        "textkey=>?,"+
        "text_query=>?,"+
        "plaintext=>TRUE,"+
        "restab=>?,"+
        "starttag=>'"+opentag+"',"+
        "endtag=>'"+closetag+"'"+
        "); "+
        "end; ";

	String ret = "";

	try{
 	 OracleCallableStatement stmt =
	    (OracleCallableStatement)conn.prepareCall(ststr);

	String setRowid=key;
	String setQuery=myQuery;
	stmt.setString(1,idxname);
	stmt.setString(2,setRowid);
       	stmt.setString(3,setQuery);
	stmt.registerOutParameter(4, OracleTypes.CLOB);
	stmt.execute();

	// read the whole chunk 
	int chunk_size=6000;
       	oracle.sql.CLOB text_clob=null;
	text_clob = ((OracleCallableStatement)stmt).getCLOB(4);
	Reader char_stream = text_clob.getCharacterStream();
	char[] char_array = new char[chunk_size];
        // initialize to spaces
        for (int i = 0; i < chunk_size; i++) {
            char_array[i] = ' ';
	}
	int n=char_stream.read(char_array);
      	String data = new String(char_array);

	// read the tag position //
	Vector opens = new Vector();
	Vector closes = new Vector();
	Vector tagterms = new Vector();
	int stpos = 0;
	do
	    {
		stpos = data.indexOf(opentag,stpos);
		int clpos = data.indexOf(closetag,stpos+1);
		if(stpos>=0 && clpos>=0)
		    {
			opens.addElement(new Integer(stpos));
			closes.addElement(new Integer(clpos));
			String str = data.substring(stpos+opentag_len,clpos);
			boolean found = false;
			for(int j = 0; j<terms.size();j++)
			    {
				String term = (String)terms.elementAt(j);
 				if(term.equalsIgnoreCase(str))
				    {
					tagterms.addElement(new Integer(j));
					found = true;
					break;
				    }
			    }
			if(!found) {tagterms.addElement(new Integer(0));}
			stpos = clpos+ closetag_len;
		    }
	    } while (stpos>=0);
	
	// find the primary segment
	int numterms = terms.size();
	int numtags = opens.size();
	int st = 0;
	int ed = 0;
	int seglen = 0;
	int maxt =0;
	for (int i=0; i<numtags; i++)
	    {
		int stp = ((Integer)(opens.elementAt(i))).intValue();
		int edp = 0;
		int[] occupied = new int[numterms];
		for (int j=0;j<numterms;j++) occupied[j] = 0;
		
		for( int j=i; j<numtags;j++ )
		    {
			int p = ((Integer)(closes.elementAt(j))).intValue();
			int sl = p-stp-(j-i+1)*(opentag_len+closetag_len);
			if(sl>150) break;
			edp = p;
			seglen = sl;
			int a = ((Integer)(tagterms.elementAt(j))).intValue();
			occupied[a] = 1;			
		    }
		int num = 0;
		for(int j=0;j<numterms;j++) { if(occupied[j]==1) num++; }
		
		if(num>maxt) 
		    {
			st = stp;
			ed = edp;
			maxt = num;		     
		    }
		if(maxt >= numterms)
		    {
			break;
		    }
	    }
	
	if(numtags<=0) { st=0; ed=st+200;}
	else 
	    {
		int wide = (200-seglen)/2;
		st = st - wide;
		if(st<0) { st = 0; }
		ed = ed + wide;
		if(ed>data.length()) {ed = data.length(); }
	    }

	// find the word boundary to adjust start and ending position
	st = adjustWordBoundary(data, st, true);
	ed = adjustWordBoundary(data, ed, false);

	// find if the position is in the middle of section
	st =  adjustSectionBoundary(data, st, true);
	ed =  adjustSectionBoundary(data, ed, false);

	ret = data.substring(st,ed);

	if (stmt != null) stmt.close();
	}
	catch(SQLException e)
	    {
		ret = "";
	    }

	if(ret.toLowerCase().indexOf(stoptag,0)>0)
	    {
		ret = "";
	    }
	return ret;
    }

    private int adjustWordBoundary(String data, int pos, boolean leftAdjust)
    {
	int ret = pos;

	if(leftAdjust)
	    {
		int spaceleft = data.lastIndexOf(' ',pos);
		if(spaceleft<0) {ret = 0; }
		else {ret = spaceleft+1; }
	    }
	else
	    {
		int spaceright = data.indexOf(' ',pos);
		if(spaceright<0){ ret = data.length(); }
		else {ret = spaceright; }	
	    }

	return ret;
    }

    private int adjustSectionBoundary(String data, int pos, boolean leftAdjust)
    {
	int ret = pos;
	int leftopen = data.lastIndexOf(opentag,pos);
	int leftclose = data.lastIndexOf(closetag,pos);
	if(leftopen>leftclose)
	    {
		if(leftAdjust)
		    {
		      ret = leftopen;	
		    }
		else
		    {
		      ret = data.indexOf(closetag,leftopen)+closetag_len;
		    }
	    }

	return ret;
    }

    public String clean (String input)
    {
	//String specialSymbols= "*\\";
      String specialSymbols= "*\\&,;?(){}[]~$!>_=%";
      StringTokenizer st = new StringTokenizer(input, specialSymbols, true);
      String phrase="";
      String specialToken;
     
      while (st.hasMoreTokens())
      {
	  String token = st.nextToken();
	  if (token.equals("\\"))
	  {
	      phrase=phrase.concat("\\\\");
	  }
	  else if (token.equals("*"))
	      phrase=phrase.concat("%");
	  else if(specialSymbols.indexOf(token)>0)
	      phrase=phrase.concat("\\"+token);
	  else
	      phrase=phrase.concat(token);
      }
    
      if(phrase.equals("+")||phrase.equals("-")||phrase.equals("|")){
	  specialToken="\\"+phrase;
	  return specialToken;
      }
      else
         return phrase;
    }
    synchronized public Vector getHighlightQuery(String input)
    {
      Vector reqWords = new Vector();
      StringTokenizer st = new StringTokenizer(input, " \"", true);
      while (st.hasMoreTokens())
      {
        String token = st.nextToken();
        if (token.equals("\""))
        {
           String phrase = getQuotedPhrase(st);
           if (phrase != null)
           {
	     if(phrase.startsWith("+") || phrase.startsWith("|"))
	        {
		   reqWords.addElement(phrase.substring(1));
	        }
	     else
		{
                    reqWords.addElement(phrase);
		}
           }
        }
        else if (!token.equals(" "))
        {
	   if(token.startsWith("+") || token.startsWith("|"))
	       {
		   reqWords.addElement(token.substring(1));
	       }
	   else 
	       {
		   reqWords.addElement(token);
	       }
        }
      }
     
      return reqWords;
    }

   private String getQuotedPhrase(StringTokenizer st)
   {
      StringBuffer phrase = new StringBuffer();
      String token = null;
      while (st.hasMoreTokens() && (!(token = st.nextToken()).equals("\"")))
      {
        phrase.append(token);
      }
      return phrase.toString();
   }

}

