<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<HTML dir=LTR>
<HEAD>
<TITLE>cr_plsql</TITLE>

<LINK REL=Stylesheet TYPE="text/css" HREF="http://otn.oracle.com/pls/wocprod/WOCPROD.wwv_setting.render_css?p_lang_type=NOBIDI&p_subscriberid=1&p_styleid=1&p_siteid=0&p_rctx=P">
<META name="title" content="cr_plsql"> <META name="description" content="File = "> <META name="keywords" content=""> <META name="author" content=""> 
<BASE HREF="http://otn.oracle.com/sample_code/products/text/htdocs/query_syntax_translators/cr_plsql.sql">
<META http-equiv="Content-Type" content="text/html; charset=utf-8">
<link rel="stylesheet" href="/admin/otn_new.css" type="text/css">

</HEAD>
<BODY leftMargin="0" rightMargin="0" topMargin="0" marginheight="0" marginwidth="0" link="#000000" vlink="#000000" alink="#000000" class="PageBG">


<SCRIPT TYPE="text/javascript">
<!-- Comment out script for old browsers
function propertysheet(thingid,masterthingid,cornerid,siteid,settingssetid,settingssiteid) { popupWin = window.open("http://otn.oracle.com/pls/wocprod/WOCPROD.wwv_thinghtml.showpropertysheet?p_thingid="+thingid+"&p_masterthingid="+masterthingid+"&p_cornerid="+cornerid+"&p_siteid="+siteid+"&p_settingssetid="+settingssetid+"&p_settingssiteid="+settingssiteid,"Property_Sheet","statusbar=Y,resizable,scrollbars,width=450,height=450"); popupWin.focus(); }
//-->
</SCRIPT>
<SCRIPT TYPE="text/javascript">
<!-- Comment out script for old browsers
function folderpropertysheet(cornerid,siteid,settingssetid,settingssiteid) { popupWin = window.open("http://otn.oracle.com/pls/wocprod/WOCPROD.wwpob_page.propertysheet?p_cornerid="+cornerid+"&p_siteid="+siteid+"&p_settingssetid="+settingssetid+"&p_settingssiteid="+settingssiteid,"Property_Sheet","statusbar=Y,resizable,scrollbars,width=450,height=450"); popupWin.focus(); }
//-->
</SCRIPT>
<SCRIPT TYPE="text/javascript">
function show_task_help() {
   newWindow = window.open("http://otn.oracle.com/wocportal/page?_pageid=5,1&_dad=wocprod&_schema=WOCPROD", "Help", "menubar=1,toolbar=yes,scrollbars=1,resizable=1,width=700,height=500");
}
</SCRIPT>
<TABLE  BORDER="0" CELLSPACING="0" CELLPADDING="0" WIDTH="100%" background="/portalimages/pobtrans.gif"  HEIGHT="5"><TR ALIGN="LEFT">
<TD vAlign="top" width="100%"><TABLE  BORDER="0" WIDTH="100%" CELLPADDING="0" CELLSPACING="0" class="RegionNoBorder">
<TR>
<TD class="RegionHeaderColor" WIDTH="100%"><TABLE  BORDER="0" CELLSPACING="0" CELLPADDING="0" WIDTH="100%" >
<TR>
<TD VALIGN="top"  width="20">
<TABLE  BORDER="0" CELLSPACING="0" CELLPADDING="0" WIDTH="100%" background="/portalimages/pobtrans.gif" ><TR ALIGN="LEFT">
<TD vAlign="top" width="100%"><font class="inplacedisplayid1siteid0"><img src="/portalimages/pobtrans.gif" border="0" width="20"></font>
</TD></TR>
</TABLE></TD>
<TD VALIGN="top"  width="100%">
<TABLE  BORDER="0" CELLSPACING="0" CELLPADDING="0" WIDTH="100%" background="/portalimages/pobtrans.gif" ><TR ALIGN="LEFT">
<TD vAlign="top" width="100%">&nbsp;<BR>
<font class="inplacedisplayid1siteid0"><SCRIPT>
// These functions are used for displaying Search help page
function open_winhelp(url)
{
   window.open(url,"winhelp",'toolbar=0,location=0,directories=0,status=0,menubar=0,scrollbars=yes,resizable=yes,width=320,height=270,screenY=250,screenX=410');
}
function openWin1()
{
   var winsearchhelp = window.open("searchhelp.html", "winsearchhelp", "toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=yes,width=450,height=360");
}
</SCRIPT>

<script language="JavaScript" type="text/javascript">
header = '0';
encoding = 'iso-8859-1';
country = 'US';
language = 'en';
</script>
<script language="JavaScript" src="http://www.oracle.com/admin/jscripts/lib.js" type="text/javascript"></script>
<script language="JavaScript" type="text/javascript">
//-- lang.js: Country/language specific JS data file
//-- last updated: 8/14/2003 3:58PM - john burbridge

readInfoCookie()
var uname = ORA_UCM_INFO.firstname; //getName(user_info)
var toprow = new Array(10)
for (var i = 0; i < toprow.length; i++ ) toprow[i] = new item(i);

var tab = new Array(15)
for (var i = 0; i < tab.length; i++ ) tab[i] = new item(i);

function item(Id){
  this.id = Id, this.label = '', this.url = '', this.image = '', this.target = '_top'
}

// for countries dropdown
var c = Array(70);
for (var i = 0; i < c.length; i++ ) c[i] = new option(i);

function option(i){
  this.id = i, this.label = '', this.url = '';
  return this;
}


///-- DON'T TOUCH ABOVE THIS LINE

var strings = new Object()
strings.language_root  	=  ""
strings.signin_label	  = "Register"
strings.signin_URL		  = "http://www.oracle.com/admin/account/index.html"
strings.signout_label	  = "Sign Out"
strings.account_label	  = "Account"
strings.ident_label    	= "Welcome " + uname
strings.mem1_label     	= "If you are not " + uname + ", "
strings.mem2_label     	= "for a free Oracle Web account"


var langjsLoad = true
//alert("Language File Loaded")
</script>
<script language="Javascript">


function DrawWelcome() {
  var tmp = '';
  if (top.user_info[FNAME]) {
    tmp += '<span class="textA">' + strings.ident_label + ' ( <a class="textA" href="javascript:signout(\'' + URL + '\');">' + strings.signout_label + '</a> | <a class="textA" target="_top" href="' + strings.signin_URL + '">' + strings.account_label + '</a> )</span>';
  } else {
    tmp += "<a class=\"textA\" href=\"" + strings.signin_URL + "\" target=\"_top\">(" + strings.signin_label + ' ' +strings.mem2_label + ")</a>";
  }
  document.write(tmp);
  document.close();
}
</script>

<SCRIPT TYPE="text/javascript">
<!-- Comment out script for old browsers
function propertysheet(thingid,masterthingid,cornerid,siteid,settingssetid,settingssiteid) { popupWin = window.open("/pls/wocprod/WOCPROD.wwv_thinghtml.showpropertysheet?p_thingid="+thingid+"&p_masterthingid="+masterthingid+"&p_cornerid="+cornerid+"&p_siteid="+siteid+"&p_settingssetid="+settingssetid+"&p_settingssiteid="+settingssiteid,"Property_Sheet","statusbar=Y,resizable,scrollbars,width=450,height=450"); popupWin.focus(); }
//-->
</SCRIPT>

<SCRIPT TYPE="text/javascript">
<!-- Comment out script for old browsers
function folderpropertysheet(cornerid,siteid,settingssetid,settingssiteid) { popupWin = window.open("/pls/wocprod/WOCPROD.wwpob_page.propertysheet?p_cornerid="+cornerid+"&p_siteid="+siteid+"&p_settingssetid="+settingssetid+"&p_settingssiteid="+settingssiteid,"Property_Sheet","statusbar=Y,resizable,scrollbars,width=450,height=450"); popupWin.focus(); }
//-->
</SCRIPT>

<SCRIPT TYPE="text/javascript">
function show_task_help() {
   newWindow = window.open("/wocportal/page?_pageid=5,1&_dad=wocprod&_schema=WOCPROD", "Help", "menubar=1,toolbar=yes,scrollbars=1,resizable=1,width=700,height=500");
}
</SCRIPT>

<SCRIPT TYPE="text/javascript">
<!-- Comment out script for old browsers
function propertysheet(thingid,masterthingid,cornerid,siteid,settingssetid,settingssiteid) { popupWin = window.open("/pls/wocprod/WOCPROD.wwv_thinghtml.showpropertysheet?p_thingid="+thingid+"&p_masterthingid="+masterthingid+"&p_cornerid="+cornerid+"&p_siteid="+siteid+"&p_settingssetid="+settingssetid+"&p_settingssiteid="+settingssiteid,"Property_Sheet","statusbar=Y,resizable,scrollbars,width=450,height=450"); popupWin.focus(); }
//-->
</SCRIPT>
<SCRIPT TYPE="text/javascript">
<!-- Comment out script for old browsers
function folderpropertysheet(cornerid,siteid,settingssetid,settingssiteid) { popupWin = window.open("/pls/wocprod/WOCPROD.wwpob_page.propertysheet?p_cornerid="+cornerid+"&p_siteid="+siteid+"&p_settingssetid="+settingssetid+"&p_settingssiteid="+settingssiteid,"Property_Sheet","statusbar=Y,resizable,scrollbars,width=450,height=450"); popupWin.focus(); }
//-->
</SCRIPT>
<SCRIPT TYPE="text/javascript">
function show_task_help() {
   newWindow = window.open("/wocportal/page?_pageid=5,1&_dad=wocprod&_schema=WOCPROD", "Help", "menubar=1,toolbar=yes,scrollbars=1,resizable=1,width=700,height=500");
}
</SCRIPT>

<table width="100%" border="0" cellspacing="0" cellpadding="0">
  <tr>
    <td>
      <table cellspacing=0 cellpadding=0 width=100% border=0>
        <tr> 
          <td> 
            <table cellspacing=0 cellpadding=0 width=100% border=0 summary="Header Information">
              <tr> 
                <td height=80 align=left valign=middle rowspan=2><a href="http://otn.oracle.com"><img src="http://oracleimg.com/admin/images/otn/otn_logo.gif" hspace="0" border="0" align="middle"></a></td>
                <td width=65 valign=bottom rowspan=2> </td>
                <td align=right> 
                  <table cellspacing=0 cellpadding=0 align=right border=0 summary="MetaLink, Buy, Download, Contact Us">
                    <tr> 
                      <td valign=bottom align=center><a href="http://www.oracle.com/" target="_blank" class=legalese><img src="http://oracleimg.com/admin/images/otn/hp_ocom_icon.gif" height=33 width=32 border=0 alt="Oracle.com"><br>
                        ORACLE.COM</a></td>
                      <td width=20> </td>
                      <td valign=bottom align=center><a href="http://opn.oracle.com/" class=legalese><img src="http://oracleimg.com/admin/images/otn/hp_opn_icon.gif" height=33 width=32 border=0 alt="Oracle PartnerNetwork"><br>
                        PARTNERS</a></td>
                      <td width=20> </td>
                      <td valign=bottom align=center><a href="http://metalink.oracle.com/" class=legalese><img src="http://oracleimg.com/admin/images/otn/hp_metalink_icon.gif" height=33 width=32 border=0 alt="Metalink"><br>
                        METALINK</a></td>
                      <td width=20> </td>
                      <td valign=bottom align=center><a href="http://otn.oracle.com/software/store/discount.html" class=legalese><img src="http://oracleimg.com/admin/images/otn/hp_buy_icon.gif" height=33 width=32 border=0 alt="Buy"><br>
                        BUY</a></td>
                      <td width=20> </td>
                      <td valign=bottom align=center><a href="http://www.oracle.com/corporate/contact/" class=legalese><img src="http://oracleimg.com/admin/images/otn/hp_contact_icon.gif" height=33 width=32 border=0 alt="Contact Us"><br>
                        CONTACT US</a></td>
                      <td width=5> </td>
                    </tr>
                    <tr> 
                      <td valign=bottom colspan="10"> 
                        <table cellspacing=0 cellpadding=1 border=0 summary="Search Oracle.com and Select a Country" width="100%">
                          <tr> 
                          <FORM name="queryform"  METHOD="GET" action="http://otn.oracle.com/ultrasearch/wwws_otn/searchotn.jsp">
    <INPUT type="hidden" name="p_Action" value="Search">

                              <td nowrap> 
                                <input type="text" name="p_Query" valign=middle value="" size=8 class=legalese id=Search>
                              </td>
                              <td nowrap> <input name="Advanced" type=IMAGE src="http://oracleimg.com/admin/images/otn/hp_search_icon.gif" border="0" align="left"></td>
							  
                              <td><a href="javascript:document.queryform.submit()" class=legalese>SEARCH</a><noscript> 
                                <input type=submit value=SEARCH name="submit">
                                </noscript> </td>
                            </form>
                            <td><a href="http://otn.oracle.com/ultrasearch/wwws_otn/searchotn.jsp" class=legalese target="_top"><u>ADVANCED 
                              SEARCH</u></a> </td>
                            <form>
                              <td><label for="Select Country"><img src="http://oracleimg.com/admin/images/otn/hp_spacer.gif" width=1 height=1 alt="Select Country"><span class="legalese"> 
                                <select class=legalese onChange="location.href=this.options[selectedIndex].value" size=1 name="Select Country" id="Select Country">
                                  <option selected>SELECT COUNTRY</option>
								  <option value="http://otn.oracle.com/global/cn/">China</option>
                                  <option value="http://otn.oracle.co.jp/">Japan</option>
                                  <option value="http://otn.oracle.co.kr/">Korea</option>
                                </select>
                                <noscript> 
                                <input type=submit value=GO name="submit">
                                </noscript></span></td>
                            </form>
                          </tr>
                          <tr> 
                            <td COLSPAN="6" VALIGN="top" ALIGN="right" class="textA"> </td>
                          </tr>
                        </table>
                      </td>
                    </tr>
                  </table>
                </td>
              </tr>
              <tr> 
                <td valign=top align=right> </td>
              </tr>
                           
            </table>
          </td>
        </tr>
      </table>
    </td>
<tr>
</table></font>
</TD></TR>
</TABLE><TABLE  BORDER="0" CELLSPACING="0" CELLPADDING="0" WIDTH="100%" background="/portalimages/pobtrans.gif" ><TR ALIGN="RIGHT">
<TD vAlign="top" width="100%"><font class="inplacedisplayid1siteid0"><table align="right"><tr><td>
<script language="JavaScript" src="/admin/jscripts/portal_lib.js"></script>
<script language="JavaScript" type="text/javascript">printWelcome()</script>
</td></tr></table></font>
</TD></TR>
</TABLE></TD>
<TD VALIGN="top"  width="33%">
<TABLE  BORDER="0" CELLSPACING="0" CELLPADDING="0" WIDTH="100%" background="/portalimages/pobtrans.gif" ><TR ALIGN="LEFT">
<TD vAlign="top" width="100%"><font class="inplacedisplayid1siteid0"><img src="/portalimages/pobtrans.gif" border="0" width="20"></font>
</TD></TR>
</TABLE></TD>
</TR>
</TABLE>
</TD></TR>
</TABLE>
</TD></TR>
</TABLE><TABLE  BORDER="0" CELLSPACING="0" CELLPADDING="0" WIDTH="100%" background="/portalimages/pobtrans.gif"  HEIGHT="5"><TR ALIGN="LEFT">
<TD vAlign="top" width="100%"><TABLE  BORDER="0" WIDTH="100%" CELLPADDING="0" CELLSPACING="0" class="RegionNoBorder">
<TR>
<TD class="RegionHeaderColor" WIDTH="100%"><TABLE  BORDER="0" CELLSPACING="0" CELLPADDING="0" WIDTH="100%" >
<TR>
<TD VALIGN="top"  class="Bodyid1siteid0"  width="20">
<TABLE  BORDER="0" CELLSPACING="0" CELLPADDING="0" WIDTH="100%" class="Bodyid1siteid0" ><TR ALIGN="LEFT">
<TD vAlign="top" width="100%"><font class="inplacedisplayid1siteid0"><img src="/portalimages/pobtrans.gif" border="0" width="20"></font>
</TD></TR>
</TABLE></TD>
<TD VALIGN="top"  class="Bodyid1siteid0"  width="100%">
<TABLE  BORDER="0" CELLSPACING="0" CELLPADDING="0" WIDTH="100%" class="Bodyid1siteid0" ><TR ALIGN="LEFT">
<TD vAlign="top" width="100%"><font class="inplacedisplayid1siteid0"><table cellspacing=0 cellpadding=0 width=100% border=0 summary="Header Information">
  <tr> 
    <!-- navigation boxes -->
    <td width=100% colspan=3> 
      <table border=0 width=100% cellpadding=0 cellspacing=0 height=34 summary="Product Centers, Technology Centers, and Community">
        <tr valign=top> 
          <td width=9 height=34 rowspan=2 align=right><img src="http://oracleimg.com/admin/images/otn/hp_bar_leftside.gif" width="11" height="34" alt=""></td>
          <td nowrap background="http://oracleimg.com/admin/images/otn/hp_button_middle1.gif" height="23" valign="middle" align="left" class="textB"><a href="/products/" class="textC">&nbsp; &nbsp;PRODUCT CENTERS&nbsp; &nbsp;</a></td>
          <td width=13 height=34 rowspan=2 align=left><img src="http://oracleimg.com/admin/images/otn/hp_button_side-middle.gif" width="13" height="34" border="0" alt=""></td>
          <td nowrap background="http://oracleimg.com/admin/images/otn/hp_button_middle1.gif" height="23" valign="middle" align="left" class="textB"><a href="/tech/" class="textB">&nbsp; &nbsp;TECHNOLOGY CENTERS&nbsp; &nbsp;</a></td>
          <td width=13 height=34 rowspan=2 align=left><img src="http://oracleimg.com/admin/images/otn/hp_button_side-middle.gif" width="13" height="34" border="0" alt=""></td>
          <td nowrap background="http://oracleimg.com/admin/images/otn/hp_button_middle1.gif" height="23" valign="middle" align="left" class="textB"><a href="/community/" class="textC">&nbsp; &nbsp;COMMUNITY&nbsp; &nbsp;</a></td>
          <td width=21 height=34 rowspan=2 align=left><img src="http://oracleimg.com/admin/images/otn/hp_button_side-right.gif" width="21" height="34" border="0" alt=""></td>
          <td width="100%" background="http://oracleimg.com/admin/images/otn/hp_test.gif" rowspan=2 align=right valign=top><img src="http://oracleimg.com/admin/images/otn/hp_bar_rightside.gif" alt=""></td>
        </tr>
        <tr> 
          <td height=11 align=left background="http://oracleimg.com/admin/images/otn/hp_button_middle2.gif"><img src="http://oracleimg.com/admin/images/otn/hp_spacer.gif" width=1 height=1 alt=""></td>
          <td height=11 align=left background="http://oracleimg.com/admin/images/otn/hp_button_middle2.gif"><img src="http://oracleimg.com/admin/images/otn/hp_spacer.gif" width=1 height=1 alt=""></td>
          <td height=11 align=left background="http://oracleimg.com/admin/images/otn/hp_button_middle2.gif"><img src="http://oracleimg.com/admin/images/otn/hp_spacer.gif" width=1 height=1 alt=""></td>
          <td height=11 align=left background="http://oracleimg.com/admin/images/otn/hp_button_middle2.gif"><img src="http://oracleimg.com/admin/images/otn/hp_spacer.gif" width=1 height=1 alt=""></td>
        </tr>
      </table>
    </td>
  </tr>
</table></font>
</TD></TR>
</TABLE></TD>
<TD VALIGN="top"  class="Bodyid1siteid0"  width="20">
<TABLE  BORDER="0" CELLSPACING="0" CELLPADDING="0" WIDTH="100%" class="Bodyid1siteid0" ><TR ALIGN="LEFT">
<TD vAlign="top" width="100%"><font class="inplacedisplayid1siteid0"><img src="/portalimages/pobtrans.gif" border="0" width="20"></font>
</TD></TR>
</TABLE></TD>
</TR>
</TABLE>
</TD></TR>
</TABLE>
</TD></TR>
</TABLE><TABLE  BORDER="0" CELLSPACING="0" CELLPADDING="0" WIDTH="100%" >
<TR>
<TD VALIGN="top"  width="20">
<TABLE  BORDER="0" CELLSPACING="0" CELLPADDING="0" WIDTH="100%" background="/portalimages/pobtrans.gif" ><TR ALIGN="LEFT">
<TD vAlign="top" width="100%">&nbsp;<BR>
<font class="inplacedisplayid1siteid0"><img src="/portalimages/pobtrans.gif" border="0" width="20"></font>
</TD></TR>
</TABLE></TD>
<TD VALIGN="top"  width="188">
<TABLE  BORDER="0" CELLSPACING="0" CELLPADDING="0" WIDTH="100%" background="/portalimages/pobtrans.gif" ><TR ALIGN="LEFT">
<TD vAlign="top" width="100%"><TABLE  BORDER="0" WIDTH="100%" CELLPADDING="0" CELLSPACING="0" class="RegionNoBorder">
<TR>
<TD class="RegionHeaderColor" WIDTH="100%"><TABLE  BORDER="0" CELLSPACING="0" CELLPADDING="0" WIDTH="100%" background="/portalimages/pobtrans.gif" ><TR ALIGN="LEFT">
<TD vAlign="top" width="100%"><TABLE  BORDER="0" WIDTH="100%" CELLPADDING="0" CELLSPACING="0" class="RegionNoBorder">
<TR>
<TD class="RegionHeaderColor" WIDTH="100%"><link href="/admin/otn_new.css" rel="stylesheet" type="text/css"> 
<script language="JavaScript" src="/admin/jscripts/navtree.js"></script>
<script language="JavaScript" src="/admin/jscripts/otn_nodes.js"></script>
<script language="JavaScript" src="/admin/jscripts/ocom_format.js"></script>
<script language="JavaScript">
    var treeName = "Tree1";
    var tree = new COOLjsTreePRO (treeName, OTN_SAMPLE_CODE_NODES, TREE_FORMAT);
</script></head>

<table width="180" border="0" cellpadding="0" cellspacing="0" bgcolor="#DDDDDD" text="#000000">
<tr><td valign="top" class=gradient>
    <script language="JavaScript">
    tree.init();
</script>
</td></tr></table>


</TD></TR>
</TABLE>
</TD></TR>
</TABLE></TD></TR>
</TABLE>
</TD></TR>
</TABLE></TD>
<TD VALIGN="top"  width="100%">
<TABLE  BORDER="0" CELLSPACING="0" CELLPADDING="0" WIDTH="100%" background="/portalimages/pobtrans.gif" ><TR>
<TD COLSPAN="3" WIDTH="100%"><IMG SRC="/portalimages/pobtrans.gif" BORDER="0" HEIGHT="10" ALT=""></TD>
</TR>
<TR ALIGN="LEFT">
<TD WIDTH="10"><IMG SRC="/portalimages/pobtrans.gif" BORDER="0" HEIGHT="1" WIDTH="10" ALT=""></TD><TD vAlign="top" width="100%">set heading off
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
 
</TD><TD WIDTH="10"><IMG SRC="/portalimages/pobtrans.gif" BORDER="0" HEIGHT="1" WIDTH="10" ALT=""></TD></TR>
<TR>
<TD COLSPAN="3" WIDTH="100%"><IMG SRC="/portalimages/pobtrans.gif" BORDER="0" HEIGHT="10" ALT=""></TD>
</TR>
</TABLE></TD>
<TD VALIGN="top"  width="20">
<TABLE  BORDER="0" CELLSPACING="0" CELLPADDING="0" WIDTH="100%" background="/portalimages/pobtrans.gif" ><TR ALIGN="LEFT">
<TD vAlign="top" width="100%"><font class="inplacedisplayid1siteid0"><img src="/portalimages/pobtrans.gif" border="0" width="20"></font>
</TD></TR>
</TABLE></TD>
</TR>
</TABLE>
<TABLE  BORDER="0" CELLSPACING="0" CELLPADDING="0" WIDTH="100%" background="/portalimages/pobtrans.gif" ><TR ALIGN="LEFT">
<TD vAlign="top" width="100%"><TABLE  BORDER="0" WIDTH="100%" CELLPADDING="0" CELLSPACING="0" class="RegionNoBorder">
<TR>
<TD class="RegionHeaderColor" WIDTH="100%"><TABLE  BORDER="0" CELLSPACING="0" CELLPADDING="0" WIDTH="100%" >
<TR>
<TD VALIGN="top"  width="20">
<TABLE  BORDER="0" CELLSPACING="0" CELLPADDING="0" WIDTH="100%" background="/portalimages/pobtrans.gif" ><TR ALIGN="LEFT">
<TD vAlign="top" width="100%"><font class="inplacedisplayid1siteid0"><img src="/portalimages/pobtrans.gif" border="0" width="20"></font>
</TD></TR>
</TABLE></TD>
<TD VALIGN="top"  width="100%">
<TABLE  BORDER="0" CELLSPACING="0" CELLPADDING="0" WIDTH="100%" background="/portalimages/pobtrans.gif" ><TR ALIGN="LEFT">
<TD vAlign="top" width="100%"><font class="inplacedisplayid1siteid0"><table align=right><tr><td><SCRIPT TYPE="text/javascript">
function printerFriendly(template) {
    top.location = location.protocol 
      + '//' + location.host 
      + location.pathname 
      + '?_template=' + template;
}
</SCRIPT>
<A href="javascript: printerFriendly('/otn/content/print')" target=""><IMG 
height=15 alt="Printer View" src="/admin/images/print_17x15.gif" width=17 
border=0></A> <A class=navlink 
href="javascript: printerFriendly('/otn/content/print')" target="">Printer 
View</A> 
</td></tr></table></font>
</TD></TR>
</TABLE><TABLE  BORDER="0" CELLSPACING="0" CELLPADDING="0" WIDTH="100%" background="/portalimages/pobtrans.gif" ><TR ALIGN="LEFT">
<TD vAlign="top" width="100%"><font class="inplacedisplayid1siteid0"><!-- SiteCatalyst code version: G.4.
Copyright 1997-2003 Omniture, Inc. More info available at
http://www.omniture.com --><script language="JavaScript"><!--
/* You may give each page an identifying name, server, and channel on
the next lines. */
var s_pageName=""
var s_server=""
var s_channel=""
var s_pageType=""
var s_prop1=""
var s_prop2=""
var s_prop3=""
var s_prop4=""
var s_prop5=""
/********* INSERT THE DOMAIN AND PATH TO YOUR CODE BELOW ************/
/********** DO NOT ALTER ANYTHING ELSE BELOW THIS LINE! *************/
var s_code=' '//--></script>
<script language="JavaScript" src="/admin/jscripts/sitecat.js"></script>
<script language="JavaScript"><!--
var s_wd=window,s_tm=new Date;if(s_code!=' '){s_code=s_dc(
'oracleglobal,oracleotnlive');if(s_code)document.write(s_code)}else
document.write('<im'+'g src="http://oracleotnlive.112.2O7.net/b/ss/oracleglobal,oracleotnlive/1/G.4--FB/s'+s_tm.getTime()+'?[AQB]'
+'&j=1.0&[AQE]" height="1" width="1" border="0" alt="" />')
//--></script><script language="JavaScript"><!--
if(navigator.appVersion.indexOf('MSIE')>=0)document.write(unescape('%3C')+'\!-'+'-')
//--></script><noscript><img
src="http://oracleotnlive.112.2O7.net/b/ss/oracleglobal,oracleotnlive/1/G.4--NS/0"
height="1" width="1" border="0" alt="" /></noscript><!--/DO NOT REMOVE/-->
<!-- End SiteCatalyst code version: G.4. -->
<table cellspacing=0 cellpadding=0 width="100%" border=0>
  <tr> 
    <td width="100%" colspan=2> 
      <hr color=#DDDDDD size= 1 style="border:0; height:1px; color:#DDDDDD; background-color:#DDDDDD;" />
    </td>
  </tr>
  <tr> 
    <td width="50%"><font face=Arial size=-2>Copyright © 2004, Oracle Corporation. 
      All Rights Reserved.</font></td>
    <td width="50%"><font face=Arial size=-2> 
      <p align=right><a href="/contact/welcome.html"><font face="Arial, Helvetica, sans-serif" size="-2" font="font" color="#000000">About 
        OTN</font></a> I <a href="http://www.oracle.com/corporate/contact/"><font face="Arial, Helvetica, sans-serif" size="-2" font="font" color="#000000">Contact 
        Us</font></a> I <a href="http://oracle.com" target="_blank"><font face="Arial, Helvetica, sans-serif" size="-2" font="font" color="#000000">About 
        Oracle</font></a><font face="Arial, Helvetica, sans-serif" size="-2"> 
        I <a href="http://www.oracle.com/html/copyright.html" target="_blank"><font FONT color=#000000
size="-2">Legal Notices and Terms of Use</font></a> I <a href="http://www.oracle.com/html/privacy.html" target="_blank"><font FONT color=#000000 size="-2">Privacy 
        Statement</font></a></font></p>
      </font></td>
  </tr>
  <tr> 
    <td width="50%"></td>
    <td width="50%"><font face=Arial size=-2 font="undefined" color="#000000"> 
      <p align=right>Powered by Oracle Application Server Portal</p>
      </font></td>
  </tr>
  <tr><td><script language="JavaScript">
    RedrawAllTrees();
</script></td></tr>
</table>
</font>
</TD></TR>
</TABLE></TD>
<TD VALIGN="top"  width="20">
<TABLE  BORDER="0" CELLSPACING="0" CELLPADDING="0" WIDTH="100%" background="/portalimages/pobtrans.gif" ><TR ALIGN="LEFT">
<TD vAlign="top" width="100%"><font class="inplacedisplayid1siteid0"><img src="/portalimages/pobtrans.gif" border="0" width="20"></font>
</TD></TR>
</TABLE></TD>
</TR>
</TABLE>
</TD></TR>
</TABLE>
</TD></TR>
</TABLE><!----- show footer template = 1021417590 ----->


</BODY>
</HTML>
<!-- Page Metadata Cached On: 10-MAY-2004:06:39:32am for User:   Time Taken: 260 msecs -->
