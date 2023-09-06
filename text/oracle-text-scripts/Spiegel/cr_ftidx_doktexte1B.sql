/**
 * Create an interMedia fulltext index on tolertoler.doktexte
 *
 * @version 1.0.0, 08.06.2000
 */

connect ctxsys/ctxsys
set timing off
spool cr_ftidx_doktexte_TOLER_1B.lst


REM The above workaround uses DBMS_LOB.CREATETEMPORARY to create a cached
REM temp lob. All work is done on this LOB then it is returned to the
REM caller.
REM Hence all work is done on a cached LOB. The LOB is kept in a package
REM variable so it does not need to be allocated/opened/closed/freed for
REM each data row.

REM Example Workaround:
REM ~~~~~~~~~~~~~~~~~~~
REM Package to hold a CLOB variable - package variable saves repeated
REM create / free of the temporary LOB 
REM one package for each index, because we might get them parallelling!

CREATE OR REPLACE PACKAGE procclob_T1B IS
	tempclob_T1B clob := null;
END procclob_T1B;
/

REM Example USER_DATASTORE procedure. This performs 30 writes into
REM the temporary LOB then appends to it to simulate the sort of
REM text "concatenation" which can occur in real user_datastores
REM
REM CREATE OR REPLACE PROCEDURE irow (rid in rowid, tlob in out NOCOPY
REM clob )
REM IS
REM 	CONST VARCHAR2(4000):='this is a test string said fred';
REM 	len NUMBER;
REM BEGIN
REM 	IF DBMS_LOB.ISTEMPORARY (tlob) <> 1 THEN
REM 		RAISE_APPLICATION_ERROR ( -20000,'"IN OUT" tlob isn''t temporary');
REM 	END IF;
REM 	IF (per.llob IS null) THEN
REM 		DBMS_LOB.CREATETEMPORARY(per.llob,true);
REM    		DBMS_LOB.OPEN (per.llob, DBMS_LOB.LOB_READWRITE);
REM 	END IF;
REM 	DBMS_LOB.TRIM(per.llob,0);  -- Forget any old changes
REM
REM 	len:=LENGTH(const);
REM 	FOR i IN 0 .. 29
REM 	LOOP
REM 	DBMS_LOB.WRITE (lob_loc=>per.llob,amount=>len,
REM 		offset=>(i*len)+1,buffer=>const);
REM 	END LOOP;
REM 	DBMS_LOB.WRITEAPPEND(lob_loc=>per.llob,amount=>len,buffer=>const);
REM 	tlob:=llob;
REM END irow;
REM /

create or replace procedure prcUpddoktexte_TOLER_1B (rid in rowid,
tlob in out NOCOPY clob )
/* ========================================================================== */
/*one and only limitation: we assume vc4000 fields can be tagged within 4000c's */
/* ========================================================================== */
is

 tSIG_ID_LISTE                  VARCHAR2(4000);
 tSIG_GEO_ID_LISTE              VARCHAR2(4000);
 tSIG_SACH_ID_LISTE             VARCHAR2(4000);
 tSGEO_ID_LISTE                 VARCHAR2(4000);
 tSSACH_ID_LISTE                VARCHAR2(4000);
 tFIRMA_ID_LISTE                VARCHAR2(4000);
 tFIRMA_GEO_ID_LISTE            VARCHAR2(4000);
 tFIRMA_SACH_ID_LISTE           VARCHAR2(4000);
 tFGEO_ID_LISTE                 VARCHAR2(4000);
 tFSACH_ID_LISTE                VARCHAR2(4000);
 tPERSON_ID_LISTE               VARCHAR2(4000);
 tPERSON_LEK_ID_LISTE           VARCHAR2(4000);
 tDOK_AUTOR                     VARCHAR2(4000);
 tDOK_UEBERSCHRIFT              VARCHAR2(2000);
 tDOK_UNTERZEILE                VARCHAR2(2000);
 tDOK_OBERZEILE                 VARCHAR2(600) ;
 tDOK_VORSPANN                  VARCHAR2(3000);
 tDOK_ABSTRAKT                  VARCHAR2(4000);

 tDOK_BILDUNTERSCHRIFT			VARCHAR2(4000);
 tFK_IDOBJEKT					VARCHAR2(4000);
 tFK_IDOBJEKTRUBRIK				VARCHAR2(4000);
 tERSCHEINUNGSDATUM				VARCHAR2(4000);
 tJAHR							VARCHAR2(4000);
 tQUARTAL						VARCHAR2(4000);
 tMONAT							VARCHAR2(4000);
-- tKOPFTEXT						VARCHAR2(4000);
 tSEITE 						VARCHAR2(4000);
 tAUSGABE						VARCHAR2(4000);
 tTXT_DOKTEXT					clob;

 v_SIG_ID_LISTE                 VARCHAR2(4000);
 v_SIG_GEO_ID_LISTE             VARCHAR2(4000);
 v_SIG_SACH_ID_LISTE            VARCHAR2(4000);
 v_SGEO_ID_LISTE                VARCHAR2(4000);
 v_SSACH_ID_LISTE               VARCHAR2(4000);
 v_FIRMA_ID_LISTE               VARCHAR2(4000);
 v_FIRMA_GEO_ID_LISTE           VARCHAR2(4000);
 v_FIRMA_SACH_ID_LISTE          VARCHAR2(4000);
 v_FGEO_ID_LISTE                VARCHAR2(4000);
 v_FSACH_ID_LISTE               VARCHAR2(4000);
 v_PERSON_ID_LISTE              VARCHAR2(4000);
 v_PERSON_LEK_ID_LISTE          VARCHAR2(4000);
 v_autor			VARCHAR2(4000);
 v_abstrakt			VARCHAR2(4000);
 v_bildunters			VARCHAR2(4000);
 v_ueberunter			VARCHAR2(4000);
 v_obervordocp			VARCHAR2(4000);
 v_enddocTAG			VARCHAR2(10);
 v_DK_FK_IDOBJEKT		VARCHAR2(4000);
 v_DK_FK_IDOBJEKTRUBRIK		VARCHAR2(4000);
 v_DK_ERSCHEINUNGSDATUM 	VARCHAR2(4000);
 v_JAHR				VARCHAR2(4000);
 v_QUARTAL			VARCHAR2(4000);
 v_MONAT			VARCHAR2(4000);
-- v_KOPFTEXT			VARCHAR2(4000);
 v_SEITE						VARCHAR2(4000);
 v_AUSGABE						VARCHAR2(4000);

 l01 				number;
 l02 				number;
 l03 				number;
 l04 				number;
 l05 				number;
 l06 				number;
 l07 				number;
 l08 				number;
 l09 				number;
 l10 				number;
 l11 				number;
 l12				number;
 autorl				number;
 ueberunterl			number;
 obervordocpl			number;
 abstraktl			number;
 bilduntersl			number;
 dest_lob_offset		number;
 p				number;
 l20				number;
 l21				number;
 l22				number;
 l23				number;
 l24				number;
 l25				number;
 l26				number;
 l27				number;

begin
	if Dbms_Lob.Istemporary (tlob) <> 1 then
		raise_application_error ( -20000,'"IN OUT" tlob isn''t temporary' );
	end if;

  begin
  SELECT AUTOR,                                          
 		UEBERSCHRIFT,                                   
	 	UNTERZEILE,                                     
	 	OBERZEILE,                                      
	 	VORSPANN,                                       
	 	ABSTRAKT,                                       
 		BILDUNTERSCHRIFT,
 		txt.DOKTEXT,
 		dok.SIG_ID_LISTE,
 		SIG_GEO_ID_LISTE,
 		SIG_SACH_ID_LISTE,
 		SGEO_ID_LISTE,
 		SSACH_ID_LISTE,
 		FIRMA_ID_LISTE,
 		FIRMA_GEO_ID_LISTE,
 		FIRMA_SACH_ID_LISTE,
 		FGEO_ID_LISTE,
 		FSACH_ID_LISTE,
 		PERSON_ID_LISTE,
 		PERSON_LEK_ID_LISTE,
	    fk_idobjekt,
		fk_idobjektrubrik,
		erscheinungsdatum,  
		substr(erscheinungsdatum,1,4),
		substr(erscheinungsdatum,1,4)
			||decode(substr(erscheinungsdatum,5,2),'01','1','02','1','03','1','04','2','05','2','06','2',
				'07','3','08','3','09','3','4'),
		substr(erscheinungsdatum,1,6),
--		substr(substr(ltrim(rtrim(ueberschrift)),1,150) || ' '
--            	|| substr(ltrim(rtrim(oberzeile)),1,150) || ' '
--            	|| substr(ltrim(rtrim(unterzeile)),1,150) || ' '
--            	|| substr(ltrim(rtrim(vorspann)),1,150) || ' '
--            	|| substr(ltrim(rtrim(abstrakt)),1,150) || ' '
--            	|| doktextanfang, 1, 150),
    to_char(seiteint),
    to_char(ausgabeint)
   into		tDOK_AUTOR,
 		tDOK_UEBERSCHRIFT,                                   
	 	tDOK_UNTERZEILE,                                     
	 	tDOK_OBERZEILE,                                      
	 	tDOK_VORSPANN,                                       
	 	tDOK_ABSTRAKT,                                       
 		tDOK_BILDUNTERSCHRIFT,                              
 		tTXT_DOKTEXT,
 		tSIG_ID_LISTE,
 		tSIG_GEO_ID_LISTE,
 		tSIG_SACH_ID_LISTE,
 		tSGEO_ID_LISTE,
 		tSSACH_ID_LISTE,
 		tFIRMA_ID_LISTE,
 		tFIRMA_GEO_ID_LISTE,
 		tFIRMA_SACH_ID_LISTE,
 		tFGEO_ID_LISTE,
 		tFSACH_ID_LISTE,
 		tPERSON_ID_LISTE,
 		tPERSON_LEK_ID_LISTE,
	    tfk_idobjekt,
		tfk_idobjektrubrik,
		terscheinungsdatum,
		tjahr,
		tquartal,
		tmonat,
--		tkopftext,
		tSEITE,
	    tAUSGABE
  FROM		toler.doktexte dok,
  			toler.dokartikeltext txt
  WHERE		dok.rowid = rid
  AND		dok.fk_iddokument = txt.fk_iddokument (+)
-------------------------------------------------------------------
-- Include only certain date ranges:  
 and    	dok.erscheinungsdatum < '20001001'
-- and    	dok.erscheinungsdatum <= '21000101'
-------------------------------------------------------------------
-- Exclude some "objects":
-- and dok.fk_idobjekt NOT IN (1001590, 7001182, 1001909, 1001932)  -- Agenturmeldungen und Stern-TV
-- and dok.fk_idobjekt NOT IN (1001932)  -- Stern-TV
-------------------------------------------------------------------
  and 		dok.dokumentstatus = 'OK'  -- this is a copy of dokument.status!
  and		dok.exportierbar='1';
  EXCEPTION
/*
Es gibt folgende interessante Fälle:
- Erstindizierung, Dokument hat falschen Status/exportierbar-Flag -> nicht indizieren
- Nachindizierung, Dokument wurde gültig -> Dokument neu indizieren
- Nachindizierung, Dokument wurde ungültig -> Dokument aus Index entfernen!
- Kein passender Eintrag in dokartikeltext -> doktext leer annehmen, indizieren
- Mehrere passende Einträge in dokartikeltext -> Exception hochreichen; Protokollierung?
*/

    -- No matching document exists (probably status and/or exportierbar have
    -- "wrong" values) - do not index anything
    when NO_DATA_FOUND then 
	begin
		Dbms_Lob.Trim  (tlob,newlen=>0);
	--  null;
	end;
	-- In case more than one matching document exists do not catch the exception
  end;


  v_SIG_ID_LISTE        := '<SIG_ID_LISTE>'		|| 	tSIG_ID_LISTE		|| '</SIG_ID_LISTE>';
  v_SIG_GEO_ID_LISTE    := '<SIG_GEO_ID_LISTE>'		|| 	tSIG_GEO_ID_LISTE	|| '</SIG_GEO_ID_LISTE>';
  v_SIG_SACH_ID_LISTE   := '<SIG_SACH_ID_LISTE>'	|| 	tSIG_SACH_ID_LISTE	|| '</SIG_SACH_ID_LISTE>';         
  v_SGEO_ID_LISTE       := '<SGEO_ID_LISTE>'		|| 	tSGEO_ID_LISTE		|| '</SGEO_ID_LISTE>';         
  v_SSACH_ID_LISTE      := '<SSACH_ID_LISTE>'		|| 	tSSACH_ID_LISTE		|| '</SSACH_ID_LISTE>';         
  v_FIRMA_ID_LISTE      := '<FIRMA_ID_LISTE>'		|| 	tFIRMA_ID_LISTE		|| '</FIRMA_ID_LISTE>';         
  v_FIRMA_GEO_ID_LISTE  := '<FIRMA_GEO_ID_LISTE>'	|| 	tFIRMA_GEO_ID_LISTE	|| '</FIRMA_GEO_ID_LISTE>';         
  v_FIRMA_SACH_ID_LISTE := '<FIRMA_SACH_ID_LISTE>'	|| 	tFIRMA_SACH_ID_LISTE	|| '</FIRMA_SACH_ID_LISTE>';         
  v_FGEO_ID_LISTE       := '<FGEO_ID_LISTE>' 		|| 	tFGEO_ID_LISTE		|| '</FGEO_ID_LISTE>';         
  v_FSACH_ID_LISTE      := '<FSACH_ID_LISTE>' 		|| 	tFSACH_ID_LISTE		|| '</FSACH_ID_LISTE>';         
  v_PERSON_ID_LISTE     := '<PERSON_ID_LISTE>' 		|| 	tPERSON_ID_LISTE	|| '</PERSON_ID_LISTE>';         
  v_PERSON_LEK_ID_LISTE := '<PERSON_LEK_ID_LISTE>' 	|| 	tPERSON_LEK_ID_LISTE	|| '</PERSON_LEK_ID_LISTE>';
  v_autor	:= '<AUTOR>'		|| tDOK_AUTOR			||	'</AUTOR>';
  v_abstrakt	:= '<ABSTRAKT>'		|| tDOK_ABSTRAKT		||	'</ABSTRAKT>';
  v_bildunters  := '<BILDUNTERSCHRIFT>'	|| tDOK_BILDUNTERSCHRIFT	||	'</BILDUNTERSCHRIFT>';
  v_ueberunter  := '<UEBERSCHRIFT>'	|| tDOK_UEBERSCHRIFT		||	'</UEBERSCHRIFT>'	||
  		   '<UNTERZEILE>'	|| tDOK_UNTERZEILE		||	'</UNTERZEILE>';
  v_obervordocp	:= '<OBERZEILE>'	|| tDOK_OBERZEILE		||	'</OBERZEILE>'		||
  		   '<VORSPANN>'		|| tDOK_VORSPANN		||	'</VORSPANN>';
  v_DK_FK_IDOBJEKT := '<FK_IDOBJEKT>' 	|| tFK_IDOBJEKT	|| '</FK_IDOBJEKT>';
  v_DK_FK_IDOBJEKTRUBRIK := '<FK_IDOBJEKTRUBRIK>' 	|| tFK_IDOBJEKTRUBRIK	|| '</FK_IDOBJEKTRUBRIK>';
  v_DK_ERSCHEINUNGSDATUM := '<ERSCHEINUNGSDATUM>' 	|| tERSCHEINUNGSDATUM	|| '</ERSCHEINUNGSDATUM>';
  v_JAHR 		 := '<JAHR>' 	|| tJAHR	|| '</JAHR>';
  v_QUARTAL 		 := '<QUARTAL>' 	|| tQUARTAL	|| '</QUARTAL>';
  v_MONAT 		 := '<MONAT>' 	|| tMONAT	|| '</MONAT>';
--  v_KOPFTEXT 		 := '<KOPFTEXT>' 	|| tKOPFTEXT	|| '</KOPFTEXT>';
  v_SEITE 		 := '<SEITE>' 	|| tSEITE	|| '</SEITE>';
  v_AUSGABE 		 := '<AUSGABE>' 	|| tAUSGABE	|| '</AUSGABE>' || '<DOKTEXT>';
  v_enddocTAG   := '</DOKTEXT>';  		   
  
  
  l01		:= length(v_SIG_ID_LISTE);
  l02		:= length(v_SIG_GEO_ID_LISTE);
  l03		:= length(v_SIG_SACH_ID_LISTE);
  l04		:= length(v_SGEO_ID_LISTE);
  l05		:= length(v_SSACH_ID_LISTE);
  l06		:= length(v_FIRMA_ID_LISTE);
  l07		:= length(v_FIRMA_GEO_ID_LISTE);
  l08		:= length(v_FIRMA_SACH_ID_LISTE);
  l09		:= length(v_FGEO_ID_LISTE);
  l10		:= length(v_FSACH_ID_LISTE);
  l11 		:= length(v_PERSON_ID_LISTE);
  l12 		:= length(v_PERSON_LEK_ID_LISTE);
  autorl	:= length(v_autor);
  ueberunterl	:= length(v_ueberunter);
  obervordocpl	:= length(v_obervordocp);
  abstraktl	:= length(v_abstrakt);
  bilduntersl	:= length(v_bildunters);
  l20		:= length(v_DK_FK_IDOBJEKT);
  l21 		:= length(v_DK_FK_IDOBJEKTRUBRIK);
  l22 		:= length(v_DK_ERSCHEINUNGSDATUM);
  l23 		:= length(V_JAHR);
  l24 		:= length(v_QUARTAL);
  l25 		:= length(v_MONAT);
--  l26 		:= length(v_KOPFTEXT);
  l27 		:= length(v_SEITE);
 
/* for varchars */
 
/*  
	alte Form
	Dbms_Lob.Trim  (lob_loc=>tlob,newlen=>0);
	Dbms_Lob.Write (lob_loc=>tlob,amount=>l01,		offset=>1,
  		  buffer=>v_SIG_ID_LISTE);
	Neue Form
REM 	DBMS_LOB.WRITE (lob_loc=>per.llob,amount=>len,
REM 		offset=>(i*len)+1,buffer=>const);
REM 	DBMS_LOB.WRITEAPPEND(lob_loc=>per.llob,amount=>len,buffer=>const);
*/
/* Lege temporaere CLOB an */
	IF (procclob_T1B.tempclob_T1B IS null) THEN
		DBMS_LOB.CREATETEMPORARY(procclob_T1B.tempclob_T1B,true);
		DBMS_LOB.OPEN (procclob_T1B.tempclob_T1B, DBMS_LOB.LOB_READWRITE);
	END IF;
/* Alte Information in schon gebrauchtem CLOB loeschen */
	Dbms_Lob.Trim  (lob_loc=>procclob_T1B.tempclob_T1B,newlen=>0);
/* Jetzt in temp. CLOB alle Felder schreiben */
	Dbms_Lob.Write (lob_loc=>procclob_T1B.tempclob_T1B,amount=>l01,		offset=>1,
			  buffer=>v_SIG_ID_LISTE);
	Dbms_Lob.Write (lob_loc=>procclob_T1B.tempclob_T1B,amount=>l02,		offset=>l01+1,
			  buffer=>v_SIG_GEO_ID_LISTE);
	Dbms_Lob.Write (lob_loc=>procclob_T1B.tempclob_T1B,amount=>l03,		offset=>l01+l02+1,
			  buffer=>v_SIG_SACH_ID_LISTE);
	Dbms_Lob.Write (lob_loc=>procclob_T1B.tempclob_T1B,amount=>l04,		offset=>l01+l02+l03+1,
			  buffer=>v_SGEO_ID_LISTE);
	Dbms_Lob.Write (lob_loc=>procclob_T1B.tempclob_T1B,amount=>l05,
		offset=>l01+l02+l03+l04+1,
		buffer=>v_SSACH_ID_LISTE);
	Dbms_Lob.Write (lob_loc=>procclob_T1B.tempclob_T1B,amount=>l06,
		offset=>l01+l02+l03+l04+l05+1,
		buffer=>v_FIRMA_ID_LISTE);
	Dbms_Lob.Write (lob_loc=>procclob_T1B.tempclob_T1B,amount=>l07,
		offset=>l01+l02+l03+l04+l05+l06+1,
		buffer=>v_FIRMA_GEO_ID_LISTE);
	Dbms_Lob.Write (lob_loc=>procclob_T1B.tempclob_T1B,amount=>l08,
		offset=>l01+l02+l03+l04+l05+l06+l07+1,
		buffer=>v_FIRMA_SACH_ID_LISTE);
	Dbms_Lob.Write (lob_loc=>procclob_T1B.tempclob_T1B,amount=>l09,
		offset=>l01+l02+l03+l04+l05+l06+l07+l08+1,
		buffer=>v_FGEO_ID_LISTE);
	Dbms_Lob.Write (lob_loc=>procclob_T1B.tempclob_T1B,amount=>l10,
		offset=>l01+l02+l03+l04+l05+l06+l07+l08+l09+1,
		buffer=>v_FSACH_ID_LISTE);
	Dbms_Lob.Write (lob_loc=>procclob_T1B.tempclob_T1B,amount=>l11,
		offset=>l01+l02+l03+l04+l05+l06+l07+l08+l09+l10+1,
		buffer=>v_PERSON_ID_LISTE);
	Dbms_Lob.Write (lob_loc=>procclob_T1B.tempclob_T1B,amount=>l12,
		offset=>l01+l02+l03+l04+l05+l06+l07+l08+l09+l10+l11+1,
		buffer=>v_PERSON_LEK_ID_LISTE);
 
	p := l01+l02+l03+l04+l05+l06+l07+l08+l09+l10+l11+l12+1;
 
/* autor */  
	Dbms_Lob.Write (lob_loc=>procclob_T1B.tempclob_T1B,amount=>autorl,		offset=>p,
			  buffer=>v_autor);
/* abstrakt */
	Dbms_Lob.Write (lob_loc=>procclob_T1B.tempclob_T1B,amount=>abstraktl,	offset=>(autorl+p),
			  buffer=>v_abstrakt);
/* bildunterschrift */ 
	Dbms_Lob.Write (lob_loc=>procclob_T1B.tempclob_T1B,amount=>bilduntersl,	offset=>(autorl+abstraktl+p),
			  buffer=>v_bildunters);
/* ueberschrift + unterzeile */
	Dbms_Lob.Write (lob_loc=>procclob_T1B.tempclob_T1B,amount=>ueberunterl,	offset=>(autorl+abstraktl+bilduntersl+p),
			  buffer=>v_ueberunter);
/* oberzeile + vorspann  + dokCLOBheaderTAG */
	Dbms_Lob.Write (lob_loc=>procclob_T1B.tempclob_T1B,amount=>obervordocpl,	offset=>(autorl+abstraktl+bilduntersl+ueberunterl+p),
			  buffer=>v_obervordocp);  		  
/* neue Spalten */
	p:= p+ autorl+abstraktl+bilduntersl+ueberunterl+obervordocpl;
	Dbms_Lob.Write (lob_loc=>procclob_T1B.tempclob_T1B,amount=>l20,		offset=>p,
			  buffer=>v_DK_FK_IDOBJEKT);
	p:=p+l20;
	Dbms_Lob.Write (lob_loc=>procclob_T1B.tempclob_T1B,amount=>l21,		offset=>p,
			  buffer=>v_DK_FK_IDOBJEKTRUBRIK);
	p:=p+l21;
	Dbms_Lob.Write (lob_loc=>procclob_T1B.tempclob_T1B,amount=>l22,		offset=>p,
			  buffer=>v_DK_ERSCHEINUNGSDATUM);
	p:=p+l22;
	Dbms_Lob.Write (lob_loc=>procclob_T1B.tempclob_T1B,amount=>l23,		offset=>p,
			  buffer=>v_JAHR);
	p:=p+l23;
	Dbms_Lob.Write (lob_loc=>procclob_T1B.tempclob_T1B,amount=>l24,		offset=>p,
			  buffer=>v_QUARTAL);
	p:=p+l24;
	Dbms_Lob.Write (lob_loc=>procclob_T1B.tempclob_T1B,amount=>l25,		offset=>p,
			  buffer=>v_MONAT);
	p:=p+l25;
--  Dbms_Lob.Write (lob_loc=>procclob_T1B.tempclob_T1B,amount=>l26,		offset=>p,
--  		  buffer=>v_KOPFTEXT);
--  p:=p+l26;
	Dbms_Lob.Write (lob_loc=>procclob_T1B.tempclob_T1B,amount=>l27,		offset=>p,
			  buffer=>v_SEITE);
	p:=p+l27;
	l27:=length(v_AUSGABE);
	Dbms_Lob.Write (lob_loc=>procclob_T1B.tempclob_T1B,amount=>l27,		offset=>p,
			  buffer=>v_AUSGABE);
	p:=p+l27;


/* for lobs */
 /* now the document lob */
	
	if not ( tTXT_DOKTEXT is null or
	         Dbms_Lob.GetLength ( tTXT_DOKTEXT ) < 1 )
	then
--    dest_lob_offset := autorl + abstraktl + bilduntersl + ueberunterl + obervordocpl + p;
	  dest_lob_offset := p;
	  Dbms_Lob.Copy  (dest_lob	=> procclob_T1B.tempclob_T1B,
	                src_lob	=> tTXT_DOKTEXT, 
	                amount	=> Dbms_Lob.GetLength(tTXT_DOKTEXT),
	                dest_offset	=> dest_lob_offset,
	                src_offset	=> 1);
	end if;

/* for varchars */
/* the last tag to append */
	Dbms_Lob.WriteAppend (lob_loc=>procclob_T1B.tempclob_T1B,amount=>length(v_enddocTAG),
		buffer=>v_enddocTAG);

 	tlob:=procclob_T1B.tempclob_T1B;

end prcUpddoktexte_TOLER_1B;
/
Show Errors
grant execute on procclob_T1B to public;
grant execute on prcUpddoktexte_TOLER_1B to public;

--quit
connect toler/anilaj

exec ctx_ddl.drop_section_group ('F_TOLER_1B');
/* Neu: XML-Lexer verwenden - hat kein Speicherleck */
exec ctx_ddl.create_section_group ('F_TOLER_1B','xml_section_group');
exec ctx_ddl.add_field_section ('F_TOLER_1B','AUTOR','AUTOR',true);
exec ctx_ddl.add_field_section ('F_TOLER_1B','ABSTRAKT','ABSTRAKT',true);
exec ctx_ddl.add_field_section ('F_TOLER_1B','BILDUNTERSCHRIFT','BILDUNTERSCHRIFT',true);
exec ctx_ddl.add_field_section ('F_TOLER_1B','UEBERSCHRIFT','UEBERSCHRIFT',true);
exec ctx_ddl.add_field_section ('F_TOLER_1B','OBERZEILE','OBERZEILE',true);
exec ctx_ddl.add_field_section ('F_TOLER_1B','VORSPANN','VORSPANN',true);
exec ctx_ddl.add_field_section ('F_TOLER_1B','DOKTEXT','DOKTEXT',true);
exec ctx_ddl.add_field_section ('F_TOLER_1B','SIG_ID_LISTE','SIG_ID_LISTE',false);
exec ctx_ddl.add_field_section ('F_TOLER_1B','SIG_GEO_ID_LISTE','SIG_GEO_ID_LISTE',false);
exec ctx_ddl.add_field_section ('F_TOLER_1B','SIG_SACH_ID_LISTE','SIG_SACH_ID_LISTE',false);
exec ctx_ddl.add_field_section ('F_TOLER_1B','SGEO_ID_LISTE','SGEO_ID_LISTE',false);
exec ctx_ddl.add_field_section ('F_TOLER_1B','SSACH_ID_LISTE','SSACH_ID_LISTE',false);
exec ctx_ddl.add_field_section ('F_TOLER_1B','FIRMA_ID_LISTE','FIRMA_ID_LISTE',false);
exec ctx_ddl.add_field_section ('F_TOLER_1B','FIRMA_GEO_ID_LISTE','FIRMA_GEO_ID_LISTE',false);
exec ctx_ddl.add_field_section ('F_TOLER_1B','FIRMA_SACH_ID_LISTE','FIRMA_SACH_ID_LISTE',false);
exec ctx_ddl.add_field_section ('F_TOLER_1B','FGEO_ID_LISTE','FGEO_ID_LISTE',false);
exec ctx_ddl.add_field_section ('F_TOLER_1B','FSACH_ID_LISTE','FSACH_ID_LISTE'	,false);
exec ctx_ddl.add_field_section ('F_TOLER_1B','PERSON_ID_LISTE','PERSON_ID_LISTE'	,false);
exec ctx_ddl.add_field_section ('F_TOLER_1B','PERSON_LEK_ID_LISTE','PERSON_LEK_ID_LISTE'	,false);
exec ctx_ddl.add_field_section ('F_TOLER_1B','FK_IDOBJEKT','FK_IDOBJEKT',false);
exec ctx_ddl.add_field_section ('F_TOLER_1B','FK_IDOBJEKTRUBRIK','FK_IDOBJEKTRUBRIK',false);
exec ctx_ddl.add_field_section ('F_TOLER_1B','ERSCHEINUNGSDATUM','ERSCHEINUNGSDATUM',false);
exec ctx_ddl.add_field_section ('F_TOLER_1B','JAHR','JAHR',false);
exec ctx_ddl.add_field_section ('F_TOLER_1B','QUARTAL','QUARTAL',false);
exec ctx_ddl.add_field_section ('F_TOLER_1B','MONAT','MONAT',false);
--exec ctx_ddl.add_field_section ('F_TOLER_1B','KOPFTEXT','KOPFTEXT',false);
exec ctx_ddl.add_field_section ('F_TOLER_1B','SEITE','SEITE',false);
exec ctx_ddl.add_field_section ('F_TOLER_1B','AUSGABE','AUSGABE',false);

exec ctx_ddl.drop_preference   ( 'cdstore_TOLER_1B' );
exec ctx_ddl.create_preference ( 'cdstore_TOLER_1B', 'user_datastore' );
exec ctx_ddl.set_attribute     ( 'cdstore_TOLER_1B', 'procedure','prcUpddoktexte_TOLER_1B' );

exec ctx_ddl.drop_stoplist  ('nulstoplist_TOLER_1B');
exec ctx_ddl.create_stoplist('nulstoplist_TOLER_1B');
exec ctx_ddl.drop_preference('STR_TOLER_1B');
exec ctx_ddl.create_preference('STR_TOLER_1B','BASIC_STORAGE');
exec ctx_ddl.drop_preference('NF_TOLER_1B');
exec ctx_ddl.create_preference('NF_TOLER_1B','NULL_FILTER');
exec ctx_ddl.drop_preference('LEXER_TOLER_1B');
exec ctx_ddl.create_preference('LEXER_TOLER_1B','BASIC_LEXER');

-- ab hier neues Wordlist wegen wildcard_maxterms, prefix indexing,
-- und substring indexing
exec ctx_ddl.drop_preference('WL_TOLER_1B');
exec ctx_ddl.create_preference('WL_TOLER_1B', 'BASIC_WORDLIST');
--exec ctx_ddl.set_attribute('WL_TOLER_1B','FUZZY_MATCH','GERMAN');
--exec ctx_ddl.set_attribute('WL_TOLER_1B','FUZZY_SCORE','0');
--exec ctx_ddl.set_attribute('WL_TOLER_1B','FUZZY_NUMRESULTS','5000');
exec ctx_ddl.set_attribute('WL_TOLER_1B','STEMMER','GERMAN');
exec ctx_ddl.set_attribute('WL_TOLER_1B','WILDCARD_MAXTERMS','15000');
exec ctx_ddl.set_attribute('WL_TOLER_1B','SUBSTRING_INDEX','FALSE');
exec ctx_ddl.set_attribute('WL_TOLER_1B','PREFIX_INDEX','NO');
exec ctx_ddl.set_attribute('WL_TOLER_1B','PREFIX_MIN_LENGTH', 3);
exec ctx_ddl.set_attribute('WL_TOLER_1B','PREFIX_MAX_LENGTH', 8);

 
exec ctx_ddl.set_attribute('LEXER_TOLER_1B','INDEX_THEMES','NO');
exec ctx_ddl.set_attribute('LEXER_TOLER_1B','ALTERNATE_SPELLING','GERMAN');
exec ctx_ddl.set_attribute('LEXER_TOLER_1B','BASE_LETTER','YES');
exec ctx_ddl.set_attribute('LEXER_TOLER_1B','BASE_LETTER_TYPE','SPECIFIC');
-- Bindestrich am Ende der Zeile:
exec ctx_ddl.set_attribute('LEXER_TOLER_1B','CONTINUATION','-');

exec ctx_ddl.set_attribute('STR_TOLER_1B','i_table_clause','PCTFREE 5 PCTUSED 75 -
 tablespace TEXT storage (initial 20M next 20M pctincrease 0 freelists 19 -
 freelist groups 19) parallel 1 nologging');
exec ctx_ddl.set_attribute('STR_TOLER_1B','k_table_clause','PCTFREE 5  tablespace TEXT storage (initial 20M next 20M pctincrease 0) nologging');
exec ctx_ddl.set_attribute('STR_TOLER_1B', 'r_table_clause','PCTFREE 5 PCTUSED 75 tablespace TEXT storage (initial 20M next 20M pctincrease 0) nologging ');
exec ctx_ddl.set_attribute('STR_TOLER_1B', 'n_table_clause','PCTFREE 5 tablespace TEXT storage (initial 20M next 20M pctincrease 0) nologging');
exec ctx_ddl.set_attribute('STR_TOLER_1B', 'i_index_clause','PCTFREE 5 tablespace TEXT storage (initial 20M next 20M pctincrease 0) nologging');
-- wegen prefix indexing
exec ctx_ddl.set_attribute('STR_TOLER_1B', 'p_table_clause','PCTFREE 5 tablespace TEXT storage (initial 20M next 20M pctincrease 0) nologging');

set timing on 

drop index idx_ft_doktexte_TOLER_1B force;

exec ctx_output.start_log('UDnoSECTION_TOLER_1B.log');

-- for 9iR2 because of parallel
--alter session enable parallel dml;
--alter session enable parallel ddl;
--alter session force parallel query;

-- hier wordlist wegen wildcardmaxterms, prefix indexing, substring indexing
create index idx_ft_doktexte_TOLER_1B on doktexte(VORSPANN) 
indextype is ctxsys.context 
parameters('section group F_TOLER_1B datastore cdstore_TOLER_1B filter NF_TOLER_1B wordlist WL_TOLER_1B lexer LEXER_TOLER_1B storage STR_TOLER_1B memory 400M stoplist nulstoplist_TOLER_1B') parallel 2;
--parameters('section group F_TOLER_1B filter NF_TOLER_1B wordlist WL_TOLER_1B lexer LEXER_TOLER_1B storage STR_TOLER_1B memory 400M stoplist nulstoplist_TOLER_1B') parallel 4;
--parameters('section group F_TOLER_1B datastore cdstore_TOLER_1B filter NF_TOLER_1B lexer LEXER_TOLER_1B storage STR_TOLER_1B memory 100M stoplist nulstoplist_TOLER_1B') parallel 8;
 
select count(*), err_text from ctx_user_index_errors
where ERR_INDEX_NAME='IDX_FT_doktexte_TOLER_1B'
group by err_text;
 
exec ctx_output.end_log;

--alter table dr$idx_ft_doktexte1B$i storage (buffer_pool keep);
--alter index dr$idx_ft_doktexte1B$x storage (buffer_pool keep);
spool off
quit

