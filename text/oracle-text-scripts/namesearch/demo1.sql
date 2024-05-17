------------------------------------------------------------------------------

BEGIN
  ctx_ddl.create_section_group('xmlgroup','xml_section_group');
END;
/


BEGIN
  ctx_ddl.create_preference ('imtlexer','basic_lexer'); 
  ctx_ddl.set_attribute ('imtlexer','index_themes','no'); 
  ctx_ddl.set_attribute('imtlexer', 'printjoins', '-,/.''');
  ctx_ddl.set_attribute('imtlexer', 'punctuations', ',');
END;
/

begin
  ctx_ddl.add_ndata_section('xmlgroup', 'Name', 'Name');
end;
/


begin
  ctx_ddl.create_preference('namewl', 'BASIC_WORDLIST');
end;
/

begin
  ctx_ddl.set_attribute('namewl', 'NDATA_BASE_LETTER', 'TRUE');
  ctx_ddl.set_attribute('namewl', 'NDATA_ALTERNATE_SPELLING', 'FALSE');
  ctx_ddl.set_attribute('namewl', 'NDATA_JOIN_PARTICLES',
   'de:di:la:da:el:del:qi:abd:los:la:dos:do:an:li:yi:yu:van:jon:un:sai:ben:al');
end;
/

CREATE INDEX xml_text_index ON ads_element (xml_descriptors)
INDEXTYPE IS Ctxsys.Context
PARAMETERS('stoplist ctxsys.EMPTY_STOPLIST filter ctxsys.null_filter section group xmlgroup lexer imtlexer');


-------------------------------------------------------------------------------------------------------------------------------------

1) I'm getting back rows with KAYS and HOSEAS instead of KAYSEAS:

SELECT xml_descriptors 
FROM ads_element
WHERE CONTAINS(xml_descriptors, 'NDATA(Name, KAYSEAS)')>0;


<descriptors>
  <barcode>2000099736</barcode>
  <IncidentID>105000178694</IncidentID>
  <TenprintKeyNumber>050-0-0178694</TenprintKeyNumber>
  <DateOfBirth>19751126</DateOfBirth>
  <FingerprintSectionNumber>763627C</FingerprintSectionNumber>
  <Name>KAYS KRIS NICHOLAS</Name>
  <Name_Surname>KAYS</Name_Surname>
  <Name_GivenName1>KRIS</Name_GivenName1>
  <Name_GivenName2>NICHOLAS</Name_GivenName2>
  <Sex>M</Sex>
  <PhotoNumber/>
  <TenprintAgency>050</TenprintAgency>
  <TypeOfFingerprintCard>0</TypeOfFingerprintCard>
  <CaseType>0</CaseType>
  <type1TypeofTrans>TENPRINT</type1TypeofTrans>
  <type1ContentType>TENPRINT</type1ContentType>
  <type1Priority>5</type1Priority>
  <type1OrigAgency>Edmonton</type1OrigAgency>
  <type1CaseID>2000099736</type1CaseID>
  <type1Date>20101113</type1Date>
  <type1Sender/>
  <type1DestAgency>Edmonton</type1DestAgency>
  <type1NativeScanningRes>39.37</type1NativeScanningRes>
  <type1NominalTransmittingRes>39.37</type1NominalTransmittingRes>
</descriptors>


<descriptors>
  <barcode>1000027770</barcode>
  <IncidentID>100000043363</IncidentID>
  <TenprintKeyNumber>000-0-0043363</TenprintKeyNumber>
  <DateOfBirth>19541127</DateOfBirth>
  <FingerprintSectionNumber>797546A</FingerprintSectionNumber>
  <Name>HOSEAS ROY WILLI</Name>
  <Name_Surname>HOSEAS</Name_Surname>
  <Name_GivenName1>ROY</Name_GivenName1>
  <Name_GivenName2>WILLI</Name_GivenName2>
  <Sex>M</Sex>
  <PhotoNumber>017730D</PhotoNumber>
  <TenprintAgency>000</TenprintAgency>
  <TypeOfFingerprintCard>0</TypeOfFingerprintCard>
  <CaseType>0</CaseType>
  <type1TypeofTrans>DESCADD</type1TypeofTrans>
  <type1ContentType>TENPRINT</type1ContentType>
  <type1Priority>5</type1Priority>
  <type1OrigAgency>Calgary</type1OrigAgency>
  <type1CaseID>1000027770</type1CaseID>
  <type1Date>20101113</type1Date>
  <type1Sender/>
</descriptors>

----------------------------------------------------------------------------------------------------------------------

