drop table d;

create table d (pk number primary key, thexml varchar2(4000));
insert into d values (1, '
<?xml version="1.0" encoding="UTF-8"?>
<Patent ID="PTAC0060"  CDLID="AC0060" timestamp="20020206170241" version="3.2.0">
<PatentDetail>
<PatentCitation><Publication CDLID="245632">
<PublicationCountry>WO</PublicationCountry>
<PublicationNumber>09010619</PublicationNumber>
</Publication>
<Title><![CDATA[Novel 1(alpha)-hydroxyvitamin D2 epimer and derivatives.]]></Title>
<AddedDate>19961031000000</AddedDate>
<UpdateDate>19961031000000</UpdateDate>
<PatentSynonym>
WO09010619 WO 09010619
</PatentSynonym>
<PatentCompanyList><PatentCompany><Company ID="CM23498" CDLID="23498">
<CompanyCitation><CompanyName><![CDATA[Wisconsin Alumni Research Foundation]]></CompanyName>
<ParentName><![CDATA[University of Wisconsin-Madison]]></ParentName>
</CompanyCitation></Company>
</PatentCompany>
</PatentCompanyList><ActionList>
<Action CDLID="647">
<ActionName><![CDATA[Calcium absorption promotor]]></ActionName>
<ActionTree><![CDATA[ START-ION-MET-CAL-AGO-]]></ActionTree>
</Action>
</ActionList>
<IndicationList>
<Indication CDLID="246">
<IndicationName><![CDATA[Osteoporosis]]></IndicationName>
<IndicationTree><![CDATA[ START-END-540-OST- START-DEG-AGE-OST- START-MUS-110-54
0-OST-]]></IndicationTree>
</Indication>
</IndicationList>
</PatentCitation>
<IsPrimaryPatent>Y</IsPrimaryPatent>
<ApplicationCountry>WO</ApplicationCountry>
<ApplicationNumber>9000952</ApplicationNumber>
<ApplicationDate>19900216000000</ApplicationDate>
<AssigneeList><![CDATA[Wisconsin Alumni Res Fdn]]></AssigneeList>
<InventorsList><![CDATA[Deluca,H; Schnoes,H; Perlman,K.]]></InventorsList>
<EstimatedExpiryDate>20090309000000</EstimatedExpiryDate>
<PublicationList>
<Publication CDLID="245632" IsDisplayPublication="Y">
<PublicationCountry>WO</PublicationCountry>
<PublicationNumber>09010619</PublicationNumber>
<PublicationDate>19900920000000</PublicationDate>
<PublicationStatusCode>A1</PublicationStatusCode>
<DesignatedStates>AT AU BE CH DE DK ES FI FR GB HU IT JP KR LU MC NL NO SE SU </
DesignatedStates>
<NumberOfDesignatedStates>20</NumberOfDesignatedStates>
</Publication>
</PublicationList>
<PFA><Abstract>
<Novelty><para>The invention claims a novel vitamin D2 compound,
1alpha-hydroxy-24-epi-vitamin D2 and its acyl and alkylsilyl derivatives.  It differs from the
 known 1alpha -hydroxyvitamin D2 by having the S-configuration at C-24.  It also
 has a remarkably different activity profile in stimulating the absorption of calcium but not its liberation from bone. The new analogue is thought to be highly
 suitable as a therapeutic agent for the prevention or treatment of conditions c
haracterised by loss of bone mass such as osteodystrophy and osteoporosis. The c
ompound has very little HL-60 cell differentiation-inducing activity.</para></Novelty>
</Abstract>
<Classification IsPrimaryClassification="Y">Oncologic, Endocrine and Metabolic</Classification>
</PFA>
<PriorityList>
<Priority ID="PR22336" CDLID="22336">
<PriorityCountry>US</PriorityCountry>
<PriorityNumber>00321254</PriorityNumber>
<PriorityDate>19890309000000</PriorityDate>
</Priority>
</PriorityList>
</PatentDetail>
<CompoundList>
<Compound ID="CPAC0060" CDLID="AC0060">
<CompoundCitation><CompoundName><![CDATA[WO-09010619]]></CompoundName>
<AddedDate>19961031000000</AddedDate>
<UpdateDate>19961031000000</UpdateDate>
</CompoundCitation></Compound>
</CompoundList>
</Patent>
');

exec ctx_ddl.drop_section_group('xsg');
exec ctx_ddl.create_section_group('xsg', 'auto_section_group');
create index di on d (thexml) indextype is ctxsys.context
parameters ('section group xsg');

select thexml from d where contains(thexml, '((ION) within Action) within ActionList') > 0;


