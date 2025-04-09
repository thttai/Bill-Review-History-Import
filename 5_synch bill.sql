USE [QA_INTM_Temp4Dts]
GO

-- =======================================
-- START SYNCH the BILL DATA
-- =======================================

-- update claim id
-- get min claim build id
--select  min(id)-1 from [INTM_ReviewWare]..claim_bill;

DECLARE @MinClaimId int = -1249937;
alter table TempBillHeader add MissingData bit, BrTaxId varchar(20), ClaimId int, ClaimBillId int identity(@MinClaimId,-1);

-- debug
--select COUNT(*) from TempBillHeader where claimId is not null;

-- find the claim no from claim table and set the id to the TempBillHeader
update TempBillHeader set -- select distinct claimnumber, claimno,
	claimId = c.id
From TempBillHeader b
join
	[INTM_ReviewWare]..[CLAIM] c (nolock) on c.claimno =  claimnumber
	and c.Edi_Source_Code = 'INTMINTC' and c.employer_id = 712;

-- debug: hardcode the claim id
-- update TempBillHeader set claimId = '299554';

-- REPORT: get headers miss the claim id
select distinct t.ClaimID, t.ClaimantFirstName, t.ClaimantLastName, convert(datetime,t.ClaimantDateofInjury) as DOI
from 	TempBillHeader t
where t.ClaimID is null

update TempBillHeader set missingData = 1
where t.ClaimID is null 



-- Create BATCH
select id, Client_ID, Employer_ID,  Status, Document_Reference from [INTM_ReviewWare]..batch where ID < 0
select * from [INTM_ReviewWare]..Client where EDI_Filter_Source_Code like 'INTMINTC'  

DECLARE @BatchId int = -25;

-- delete from [INTM_ReviewWare]..Claim_Bill_Ext where Claim_Bill_ID in (select ID from [INTM_ReviewWare]..CLAIM_BILL where Batch_ID = @BatchId);
-- delete from [INTM_ReviewWare]..CLAIM_BILL where Batch_ID = @BatchId;
-- delete from [INTM_ReviewWare]..BATCH where id = @BatchId;


set identity_insert [INTM_ReviewWare]..BATCH ON;
Insert into [INTM_ReviewWare]..BATCH (id, Client_ID, Employer_ID,  Status, Document_Reference)
Select @BatchId, 3, null, 99, 'LAWA history: BIG_EXTRACT_20170401-20250228_byclmlst' where not exists (select * from [INTM_ReviewWare]..batch where ID = @BatchId)
set identity_insert [INTM_ReviewWare]..BATCH OFF;


--update SJHeader set Comment = 'PASIS' from AMLBillHeader h
--join [INTM_ReviewWare]..CLAIM c on c.ID = h.ClaimId 
--where c.Client_ID = 61

-- select ID,
-- Batch_ID,
-- AccountNumber,
-- Claim_ID,
-- ClientRecvdDate,
-- InsertedBy,
-- DateInserted,
-- TotalCharges,
-- TotalAllowed,
-- DateOfServiceFrom,
-- DateOfServiceTo,
-- Provider_ID,
-- Provider,
-- EDI_Source_Control_Number,
-- SourceClaimNumber,
-- SourceProviderName,
-- SourceProviderPracticeName,
-- SourceProviderAddress,
-- SourceProviderCity,
-- SourceProviderState,
-- SourceProviderZip,
-- SourceProviderTaxId,
-- ProviderCheckNumber ,
-- ProviderCheckDate ,
-- ProviderCheckAmount ,
-- AttachmentInfo ,
-- Is_Duplicate ,
-- ReviewedState,
-- Provider_Patient_Account_Number from [INTM_ReviewWare]..CLAIM_BILL where Batch_ID = @BatchId;

-- select * from TempBillHeader where BillNumber = '20170403';
-- select AccountNumber, count(*) from [INTM_ReviewWare]..CLAIM_BILL group by AccountNumber having count(*) > 1;

-- select 
-- 	BillNumber,
-- 	count(*)
-- from TempBillHeader b
-- group by BillNumber;

-- select * from TempBillHeader where BillNumber = 20170417;

-- Create BILL
begin transaction;
set identity_insert [INTM_ReviewWare]..CLAIM_BILL ON;
WITH BillAggregates AS (
    SELECT 
        BillNumber,
        SUM(convert(money, [Charges])) AS TotalCharges,
        SUM(convert(money, [Allowed])) AS TotalAllowed
    FROM TempBillDetail
    GROUP BY BillNumber
)
Insert into [INTM_ReviewWare]..CLAIM_BILL (
ID,
Batch_ID,
AccountNumber,
Claim_ID,
ClientRecvdDate,
InsertedBy,
DateInserted,
TotalCharges,
TotalAllowed,
DateOfServiceFrom,
DateOfServiceTo,
Provider_ID,
Provider,
EDI_Source_Control_Number,
SourceClaimNumber,
SourceProviderName,
SourceProviderPracticeName,
SourceProviderAddress,
SourceProviderCity,
SourceProviderState,
SourceProviderZip,
SourceProviderTaxId,
ProviderCheckNumber ,
ProviderCheckDate ,
ProviderCheckAmount,
AttachmentInfo ,
Is_Duplicate ,
ReviewedState,
Provider_Patient_Account_Number
)
Select 
	ClaimBillId,
	@BatchId as  BATCHID,
	BillNumber = /*'AR' +*/ b.[BillNumber] + '-01',
	ClaimId,
	ClientRecvdDate = /*null*/[BrReceivedDate],
	InsertedBy = 'mm',
	Entry_Date = [Provider_Bill_Date],
							--Claim_Number, 
	TotalCharges = convert(money, [TotalCharges]),
	TotalAllowed = convert(money, [TotalAllowed]), 
							--ICD9Code, 
							--BillTypeCode, 
	FirstDateofService = DateOfServiceFrom, 
	LastDateofService = DateOfServiceTo,
							--DateOfBill, 
							--DateCorVelRecBill,  
							-- ReferringPhysicianName, 
							-- TaxID, Provider_Name, 
	Provider_ID = -1,
	Provider = left([ProviderTaxID],9),
	EDISourceControlNumber = b.[BillNumber], 
	SourceClaim_Number	= b.ClaimNumber,
	SourceProviderName	= left(b.[ProviderLastName] + ' '+ b.[ProviderFirstName],80),
	SourceProviderPracticeName	= left(b.[ProviderLastName] + ' '+ b.[ProviderFirstName], 60),
	SourceProviderAddress = left(rtrim(rtrim(b.[ProviderAddress1]) + ' ' + isnull([ProviderAddress2], '')), 50),
	SourceProviderCity  = left(b.[ProviderCity], 50),
	SourceProviderState	= left(b.[ProviderState], 2),
	SourceProviderZip	= left(b.[ProviderZipCode],5),
	SourceProviderTaxId	= left([ProviderTaxID],9),
	ProviderCheckNumber = null,
	ProviderCheckDate = null,
	ProviderCheckAmount = [TotalAllowed],
	AttachmentInfo = null,
	Is_Duplicate = 0,
	ReviewedState = [ReviewedState],
	Patient_Account = null
--into _Temp
From
	TempBillHeader b JOIN BillAggregates ba on b.BillNumber = ba.BillNumber				
where ISNULL(missingData,0) = 0
and b.claimbillid not in (select id from [INTM_ReviewWare]..claim_Bill cb)
and /*'AR' +*/ b.[BillNumber] + '-01' not in (select accountnumber from [INTM_ReviewWare]..claim_bill where accountnumber like 'GSRMA%');


--  select count(*) from AMLBillHeader where isnull(missingdata,0) = 0

insert into [INTM_ReviewWare]..claim_bill_ext (claim_bill_id) 
select ID from [INTM_ReviewWare]..CLAIM_BILL cb (nolock) 
where ID not in (select claim_bill_id from [INTM_ReviewWare]..claim_bill_ext);
	
	
set identity_insert [INTM_ReviewWare]..CLAIM_BILL OFF;

--update statistics [INTM_ReviewWare]..claim_bill;

IF @@ERROR = 0  
    COMMIT;  
ELSE  
    ROLLBACK;

-- select * from [INTM_ReviewWare]..CLAIM_BILL where Batch_ID = @BatchId;