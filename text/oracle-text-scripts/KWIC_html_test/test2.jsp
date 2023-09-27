<%@ page import="java.sql.*, java.util.*, java.io.*, java.net.*, oracle.jdbc.*, oracle.jdbc.pool.*, oracle.jsp.dbutil.*" %>
<%@ page contentType="text/html;charset=UTF-8" %>
<jsp:useBean id="name" class="oracle.jsp.jml.JmlString" scope ="request" >
<jsp:setProperty name="name" property="value" param="query" />
</jsp:useBean>
<jsp:useBean id="clips1" class="KWIC">
</jsp:useBean>

<%
OracleDataSource ods = new OracleDataSource();

// Set the user name, password, driver type and network protocol
ods.setUser         ("testuser");
ods.setPassword     ("testuser");
ods.setDriverType   ("thin");
ods.setServerName   ("eddie");
ods.setPortNumber   (1521);
ods.setDatabaseName ("eddi10b");

ods.setMaxStatements(1);
ods.setImplicitCachingEnabled(true);

Connection conn = null;
PreparedStatement fetchStmt0=null;
ResultSet rset0 = null;
int docid = 0;
String idstr = request.getParameter("docid");
if(idstr != null) docid = Integer.parseInt(idstr);

String rowid = null;

String query    = request.getParameter("query");
String pagestr  = request.getParameter("pagesize");

int pagesize = 20;

if (pagestr != null) pagesize = Integer.parseInt(pagestr);
%>

<HOME>
<title>
Testing Keywords in Context
</title>
<body>
<H1>Testing Keywords in Context</H1>

<P>
 <form action="test2.jsp" method="GET" >
        <table><tr><td>
        <B>Query</B>     </td><td> <input type=text size=80 name="query" value ="<%= query %>">
        </td></tr><tr><td>
	<B>Page Size</B> </td><td> <input type=text name="pagesize" value="<%= pagesize %>">
        </td></tr>
	<td></td><td><input type=submit name="action" value="submit"></td></tr></table>
        <br clear=all>
 </form>
<%
if(query != null)
{
try { 

  conn = ods.getConnection();

  String userQuery = clips1.clean(query);
  Vector highlightQuery = clips1.getHighlightQuery(userQuery);

  clips1.init(conn, highlightQuery); 

  String qry = "select s.rowid, m.file_name" + 
       " from mydocs m, mydocs_shadow s" +
       " where contains (file_name, ?) > 0" +
       " and s.mydocs_rowid = m.rowid";

  fetchStmt0=conn.prepareStatement(qry);
%>
   Hitlist for "<b><%= userQuery %></b>"
<%
  fetchStmt0.setString(1,userQuery);
  rset0 =fetchStmt0.executeQuery();

  int counter  = 0;

  String clip = "";
  String filename = "";

  rset0 =fetchStmt0.executeQuery();
  while ( rset0.next()) {
        rowid    = rset0.getString(1);  // rowid from SHADOW table
        filename = rset0.getString(2);
        counter += 1;
        if (counter > pagesize)
           break;
        clip += "<p>" + counter
         + ". Filename: " + filename
         + "<br>" + clips1.getKWIC(conn,"SHADOW_INDEX",rowid);
  }
%>
<p><hr><p>
  <%= qry %>
<p><hr><p>
  <%= clip %>
<p><hr><p>
<%
  } finally {  
      if (rset0 != null) rset0.close(); 
      if (fetchStmt0 != null) fetchStmt0.close();
      if (conn != null) conn.close();
  }
}
%>

</body>
</html>
