USE [QA_INTM_Temp4Dts]
GO

-- =======================================
-- START SYNCH the BILL DATA
-- =======================================
-- Create BATCH
select id, Client_ID, Employer_ID,  Status, Document_Reference from [QA_INTM_ReviewWare]..batch where ID < 0
select * from [QA_INTM_ReviewWare]..Client where EDI_Filter_Source_Code like 'INTMINTC'  

-- delete from [QA_INTM_ReviewWare]..Claim_Bill_Ext where Claim_Bill_ID in (select ID from [QA_INTM_ReviewWare]..CLAIM_BILL where Batch_ID = -18);
-- delete from [QA_INTM_ReviewWare]..CLAIM_BILL where Batch_ID = -18;
-- delete from [QA_INTM_ReviewWare]..BATCH where id = -18;


set identity_insert [QA_INTM_ReviewWare]..BATCH ON;
Insert into [QA_INTM_ReviewWare]..BATCH (id, Client_ID, Employer_ID,  Status, Document_Reference)
Select -18, 3, null, 99, 'LAWA history: BIG_EXTRACT_20170401-20250228_byclmlst' where not exists (select * from [QA_INTM_ReviewWare]..batch where ID = -18)
set identity_insert [QA_INTM_ReviewWare]..BATCH OFF;


--update SJHeader set Comment = 'PASIS' from AMLBillHeader h
--join [QA_INTM_ReviewWare]..CLAIM c on c.ID = h.ClaimId 
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
-- Provider_Patient_Account_Number from [QA_INTM_ReviewWare]..CLAIM_BILL where Batch_ID = -18;

-- select * from TempBillHeader where BillNumber = '20170403';
-- select AccountNumber, count(*) from [QA_INTM_ReviewWare]..CLAIM_BILL group by AccountNumber having count(*) > 1;

-- select 
-- 	BillNumber,
-- 	count(*)
-- from TempBillHeader b
-- group by BillNumber;

-- select * from TempBillHeader where BillNumber = 20170417;

-- Create BILL
begin transaction;
set identity_insert [QA_INTM_ReviewWare]..CLAIM_BILL ON;
WITH BillAggregates AS (
    SELECT 
        BillNumber,
        SUM(convert(money, [Charges])) AS TotalCharges,
        SUM(convert(money, [Allowed])) AS TotalAllowed
    FROM TempBillDetail
    GROUP BY BillNumber
)
Insert into [QA_INTM_ReviewWare]..CLAIM_BILL (
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
	-18 as  BATCHID,
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
and b.claimbillid not in (select id from [QA_INTM_ReviewWare]..claim_Bill cb)
and /*'AR' +*/ b.[BillNumber] + '-01' not in (select accountnumber from [QA_INTM_ReviewWare]..claim_bill where accountnumber like 'GSRMA%');


--  select count(*) from AMLBillHeader where isnull(missingdata,0) = 0

insert into [QA_INTM_ReviewWare]..claim_bill_ext (claim_bill_id) 
select ID from [QA_INTM_ReviewWare]..CLAIM_BILL cb (nolock) 
where ID not in (select claim_bill_id from [QA_INTM_ReviewWare]..claim_bill_ext);
	
	
set identity_insert [QA_INTM_ReviewWare]..CLAIM_BILL OFF;

--update statistics [QA_INTM_ReviewWare]..claim_bill;

IF @@ERROR = 0  
    COMMIT;  
ELSE  
    ROLLBACK;

-- select * from [QA_INTM_ReviewWare]..CLAIM_BILL where Batch_ID = -18;