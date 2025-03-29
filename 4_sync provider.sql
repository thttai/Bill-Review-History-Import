/*******************************************************************************
* Bill Review History Import Script
* Purpose: Parse fixed-width bill data into structured SQL tables
* Process: Import column definitions → Import bill data → Parse fields → Create views
*******************************************************************************/

USE [QA_INTM_Temp4Dts]
GO

select count(*) from Medata_LAWA_BIG_EXTRACT_20170401_20250228;

-- drop view
--if OBJECT_ID('[viewMedataSiaLwpBillDetail]') > 0 drop view [viewMedataSiaLwpBillDetail]; 

GO
CREATE View [dbo].[viewMedataSiaLwpBillDetail] as
select --top 100
    DateofService        =    case when isdate(DateofService) = 1 then convert(datetime,DateofService)    else null end
    ,CptCode            =    left(replace(ProcedureCodeorServiceCode,'-',''),11)
    ,Modifier1            =    case when Modifier1 = '00' then null else Modifier1 end
    ,Modifier2            =    case when Modifier2 = '00' then null else Modifier2 end

    ,PlaceOfService    =    rtrim(POS)
    ,Units                    =    NumberDone
    ,Charges
    ,ReviewReductions
    ,Allowed    =    RecommendedAllowance
    ,PPODiscount        =    PPOReduction
    ,Billed_Code        =    replace(OriginalProcedureCode,'-','')
    ,RevenueCode        =    UBRevenueCode
    ,BillNumber        = left(BillID,16)
    ,Line_Sequence_no    =    convert(bigint,CustomerLineNumber)
    ,StateCode = Case When StateCode1 like '00%' then '' else RTRIM(STateCode1) end
    + Case When StateCode2 like '00%' then '' else ',' + RTRIM(STateCode2) end
    + Case When StateCode3 like '00%' then '' else ',' + RTRIM(STateCode3) end
    + Case When StateCode4 like '00%' then '' else ',' + RTRIM(STateCode4) end
    + Case When StateCode5 like '00%' then '' else ',' + RTRIM(StateCode5) end
    + Case When StateCode6 like '00%' then '' else ',' + RTRIM(StateCode6) end
--into MedDataBillDetail    
from
    Medata_LAWA_BIG_EXTRACT_20170401_20250228

GO
CREATE View [dbo].[viewMedataSiaLwpBillHeader] as (
Select distinct --top 10
    BillDateInserted    =    convert(Datetime,BillIDDate)

    --,PlaceOfService    =    rtrim(POS)
    
    ,ClaimNumber        =    rtrim(ClaimID)
    ,BillNumber        = left(BillID,16)
    ,ICD9code1        = RTRIM(ICD9code1)
    ,ICD9code2        = RTRIM(ICD9code2)
    ,ICD9code3        = RTRIM(ICD9code3)
    ,ICD9code4        = RTRIM(ICD9code4)
    ,PpoNetwork        =    RTRIM(PPOID)
    ,Provider_Bill_Date        = case when convert(int,datebilled) > 0 then convert(datetime,DateBilled)    else null end
    ,BrReceivedDate            = case when convert(int,DateReceived1) > 0 then convert(datetime,DateReceived1)   else null end
    ,ProviderCheckDate        = case when convert(int,DatePaid) > 0 then convert(datetime,DatePaid)   else null end
    ,ProviderID
    ,ProviderTaxID        =    REPLACE(ProviderTaxID,'-','')
    ,ProviderLastName        = RTRIM(ProviderLastName)
    ,ProviderFirstName        = RTRIM(ProviderFirstName)
    ,ProviderMI        = RTRIM(ProviderMI)
    ,ProviderAddress1        = RTRIM(ProviderAddress1)
    ,ProviderAddress2        = RTRIM(ProviderAddress2)
    ,ProviderCity        = RTRIM(ProviderCity)
    ,ProviderState        = RTRIM(ProviderState)
    ,ProviderZipCode    =    LEFT(ProviderZipCode, 5)
    ,ReviewedState = RTRIM([ReviewStateClaim])
    ,AdjustmentReasonCode    = case when AdjustmentReasonCode in ('000') then null else AdjustmentReasonCode end
    ,UB92_Billed_DRG_No        = case when DRGCode in ('000') then null else DRGCode end    
    ,UB92_Admit_Date        =    case when ISDATE(AdmissionDate) = 1 then convert(datetime,AdmissionDate) else null end
    --,DateOfServiceFrom        =    case when ISDATE(BOSDate) = 1 then convert(datetime,BOSDate) else null end                BAD DATA DETECT
    --,DateOfServiceTo        =    case when ISDATE(EOSDate) = 1 then convert(datetime,EOSDate) else null end
    ,BillTypeCode            =    BillTypeCode    -- select distinct BillTypeCode from meddatacwall
    --,HospitalBillFlag            -- select distinct HospitalBillFlag from meddatacwall
    ,FormType                =    case when [IPOPFlag] in ('IP', 'OP') then 'UB04' else 'HCFA' end
    ,UB92_Discharge_Status    =    RTRIM(DischargeStatus)        -- select distinct DischargeStatus from meddatacwall
    ,Provider_Patient_Account_Number    =    RTRIM(PatientAccountID)
    ,ClaimantLastName
    ,ClaimantFirstName
    ,ClaimantDateofInjury = convert(datetime,ClaimantDateofInjury)
    ,ClaimantDateofBirth = convert(datetime,ClaimantDateofBirth)
From
    Medata_LAWA_BIG_EXTRACT_20170401_20250228
)

-- debug
--select top 10 * from [viewMedataSiaLwpBillDetail];
--select top 10 * from [viewMedataSiaLwpBillHeader];
--select count(*) from [viewMedataSiaLwpBillDetail];
--select count(*) from [viewMedataSiaLwpBillHeader];


if OBJECT_ID('TempBillHeader') > 0 drop table TempBillHeader; 
if OBJECT_ID('TempBillDetail') > 0 drop table TempBillDetail; 

-- create tables from views
SELECT *
INTO TempBillDetail
FROM [viewMedataSiaLwpBillDetail];

SELECT *
INTO TempBillHeader
FROM [viewMedataSiaLwpBillHeader];

-- debug
--select top 1 * from TempBillDetail;
--select top 1 * from TempBillHeader;
--select ClaimNumber, RIGHT(claimnumber,6), SUBSTRING(claimnumber,7, len(claimnumber) - 5) from TempBillHeader ;

-- get min claim build id
--select  min(id)-1 from [2CS_CompWare3]..claim_bill;

alter table TempBillHeader add MissingData bit, BrTaxId varchar(20), ClaimId int, ClaimBillId int identity(-1100225,-1);


---- debug
--select claimno from claim;
--select RIGHT(claimnumber, 7) from TempBillHeader;
---- for debug, fill the last 7 chars of claimnumber of table TempBillHeader to the claimno of Claim table where Edi_Source_Code = 'INTMINTC'
---- for example, TempBillHeader has 1000 records and Claim has 2000 records with Edi_Source_Code = 'INTMINTC', set first 1000 records of claimno to the last 7 chars of claimnumber of TempBillHeader
--WITH TempBillSubset AS (
--    SELECT claimnumber, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn
--    FROM TempBillHeader
--),
--ClaimSubset AS (
--    SELECT id, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn
--    FROM claim
--    WHERE Edi_Source_Code = 'INTMINTC'
--)
--UPDATE c
--SET claimno = RIGHT(t.claimnumber, 7)
--FROM claim c
--JOIN ClaimSubset cs ON c.id = cs.id
--JOIN TempBillSubset t ON cs.rn = t.rn;

-- debug
--select count(*) from TempBillDetail;
--select count(*) from TempBillHeader;
--select COUNT(DISTINCT claimno) from claim;
--select COUNT(DISTINCT claimnumber) from TempBillHeader;

-- debug
--select COUNT(*) from TempBillHeader where claimId is not null;

-- find the claim no from claim table and set the id to the TempBillHeader
update TempBillHeader set -- select distinct claimnumber, claimno,
	claimId = c.id
From TempBillHeader b
join 
	[QA_INTM_ReviewWare]..[CLAIM] c (nolock) on c.claimno =  RIGHT(claimnumber,7)
	and c.Edi_Source_Code = 'INTMINTC';

-- debug: hardcode the claim id
update TempBillHeader set claimId = '299554';

-- REPORT: get headers miss the claim id
select distinct t.ClaimID, t.ClaimantFirstName, t.ClaimantLastName, convert(datetime,t.ClaimantDateofInjury) as DOI
from 	TempBillHeader t
where t.ClaimID is null



------------------
-- SYNCH PROVIDER
------------------

-- check to create CorvelProvider
if OBJECT_ID('dbo.CorvelProvider', 'U') IS NULL
begin
create table CorvelProvider (
    ID INT IDENTITY PRIMARY KEY,      -- Unique identifier
    TaxId VARCHAR(11),
    ProviderName VARCHAR(100),
    LastName VARCHAR(30),
    FirstName VARCHAR(20),
    PracticeAddress VARCHAR(100),
	PracticeAddress2 VARCHAR(100),
	PracticeCity VARCHAR(100),
	PracticeState VARCHAR(100),
	PracticeZip VARCHAR(100),
	BrPostFixTaxId VARCHAR(100),
	IsNew INT DEFAULT 1,
);
end

-- Create index after table creation
CREATE INDEX IX1_CorvelProvider 
ON dbo.CorvelProvider (ProviderName, PracticeAddress, TaxId);

-- debug
select top 10 * from CorvelProvider

-- insert into CorvelProvider
begin transaction
insert into CorvelProvider
(ProviderName, PracticeAddress, PracticeAddress2,
PracticeCity, PracticeState, PracticeZip, TaxID)
SELECT Distinct
left(h.ProviderFirstName + ' ' + h.ProviderLAstNAme,100) as ProviderName, 
left(h.ProviderAddress1,50) as PracticeAddress, 
left(h.ProviderAddress2,50) as PracticeAddress2,
left(h.ProviderCity,15) as PracticeCity, left(h.ProviderState,2) as PracticeState, 
left(h.ProviderZipCode,5) as PracticeZip, left(h.ProviderTaxID,9) as TaxID
--,ProviderLicenseNumber -- dont get the license else too many dup return
--into CorvelProvider
from TempBillHeader h 
left join CorvelProvider p on h.ProviderFirstName + ' ' + h.ProviderLAstNAme = p.providerNAme and h.ProviderAddress1 = p.PracticeAddress and h.ProviderTaxID = p.TaxId
-- where isnull(ClaimId,0) > 0 and p.providername is null
where p.providername is null
--order by 1
select * from corvelprovider where  BrPostFixTaxId is null

IF @@ERROR = 0  
    COMMIT;  
ELSE  
    ROLLBACK;

-- debug, find null TaxId
select * from CorvelProvider where TaxId is null OR TaxId = '';


-- Generate TAXID postfix from BR
update CorvelProvider set
	BrPostFixTaxId = [dbo].[fnGet2csProviderTaxIdExt](TaxId, null)
Where isnew = 1;

-- debug, get all records from CorvelProvider
select * from CorvelProvider where TaxId = '270276119';
--select COUNT(*) from Provider where LEFT(taxid,9) = '270276119';


-- Due to dup taxid, reindex the postfix again
with cte (id, taxid, TaxidCounter) as
( 
select ID, TaxID, row_number() over (partition by taxid order by id) from CorvelProvider where isnew = 1
) 
 update CorvelProvider set 
-- select *,
	BrPostFixTaxId = right('000' + convert(varchar,convert(int,BrPostFixTaxId) + cte.TaxIdCounter - 1),4)
from CorvelProvider p
join cte on cte.id = p.id
where isnew = 1
;

-- debug
--select * from CorvelProvider where IsNew = 1 order by BrPostFixTaxId desc;
---- add colum ProviderLicenseNumber and update data from TempBillHeader
--Alter Table CorvelProvider add  ProviderLicenseNumber varchar(30);
--update CorvelProvider set p.ProviderLicenseNumber = h.ProviderLicenseNumber 
--from TempBillHeader h
--join CorvelProvider p on h.ProviderFirstName + ' ' + h.ProviderLAstNAme = p.providerNAme and h.ProviderTaxID = p.TaxId
--where p.isnew =1;

--select top 10 ID, StateLicenseNo, PracticeName, PracticeName, BillingAddress1, BillingCity, BillingState, BillingZip, ContactAddress1, ContactCity, ContactState, ContactZip, TaxId from PROVIDER;
--select * from CorvelProvider;

BEGIN TRANSACTION;
ALTER TABLE PROVIDER DISABLE TRIGGER ALL;
INSERT INTO PROVIDER (
    StateLicenseNo, 
    PracticeName, 
    BillingAddress1, 
    BillingCity, 
    BillingState, 
    BillingZip, 
    ContactAddress1, 
    ContactCity, 
    ContactState, 
    ContactZip,
    TaxId,
    Status,
    SameAsContact
)
SELECT 
    LEFT(ProviderLicenseNumber, 10), 
    LEFT(ProviderName, 160), 
    LEFT(PracticeAddress, 50), 
    PracticeCity, 
    PracticeState, 
    PracticeZip, 
    LEFT(PracticeAddress, 50), 
    PracticeCity, 
    PracticeState, 
    PracticeZip, 
    CONVERT(VARCHAR, TaxId) + '-' + ISNULL(BrPostFixTaxId, '0000'),
    9,
    0
FROM CorvelProvider 
WHERE IsNew = 1;

ALTER TABLE PROVIDER ENABLE TRIGGER ALL;

IF @@ERROR = 0  
    COMMIT;  
ELSE  
    ROLLBACK;


-- debug
select * from PROVIDER;
