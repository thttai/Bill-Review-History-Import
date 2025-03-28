-- =======================================
-- START SYNCH the BILL DATA
-- =======================================
-- BATCH
select * from [QA_INTM_ReviewWare]..batch where ID < 0
select * from [QA_INTM_ReviewWare]..Client where EDI_Filter_Source_Code like 'INTMINTC'  

set identity_insert [QA_INTM_ReviewWare]..BATCH ON;
Insert into [QA_INTM_ReviewWare]..BATCH (id, Client_ID, Employer_ID,  Status, Document_Reference)
Select -24, 3, null, 99, 'San J External history' where not exists (select * from [QA_INTM_ReviewWare]..batch where ID = -24)
set identity_insert [QA_INTM_ReviewWare]..BATCH OFF;


--update SJHeader set Comment = 'PASIS' from AMLBillHeader h
--join [QA_INTM_ReviewWare]..CLAIM c on c.ID = h.ClaimId 
--where c.Client_ID = 61

-- BILL
begin transaction;
set identity_insert [QA_INTM_ReviewWare]..CLAIM_BILL ON;
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
ProviderCheckAmount ,
AttachmentInfo ,
Is_Duplicate ,
ReviewedState,
Provider_Patient_Account_Number
)
Select 
	ClaimBillId,
	-24 as  BATCHID,
	BillNumber = /*'AR' +*/ [Bill_ID] + '-01',
	ClaimId,
	ClientRecvdDate = /*null*/[ClientRecievedDate],
	InsertedBy = 'mm',
	Entry_Date = [BillDate],
							--Claim_Number, 
	Charge = convert(money, [Charges]),
	Allowance = convert(money, [Final_Allowance]), 
							--ICD9Code, 
							--BillTypeCode, 
	FirstDateofService = DosFrom, 
	LastDateofService = DosTo,
							--DateOfBill, 
							--DateCorVelRecBill,  
							-- ReferringPhysicianName, 
							-- TaxID, Provider_Name, 
	Provider_ID = -1,
	Provider = left([Provider_Tax_ID],9),
	EdiSourceControlNumber = [Bill_ID], 
	SourceClaim_Number	= b.Claim_Id,
	SourceProviderName	= left(b.[Provider_Last_Name] + ' '+ b.[Provider_First_Name],80),
	SourceProviderPracticeName	= left(b.[Provider_Last_Name] + ' '+ b.[Provider_First_Name], 60),
	SourceProviderAddress = left(rtrim(rtrim(b.[Provider_Address_1]) + ' ' + isnull([Provider_Address_2], '')), 50),
	SourceProviderCity  = left(b.[Provider_City], 50),
	SourceProviderState	= left(b.[Provider_State], 2),
	SourceProviderZip	= left(b.[Provider_Zip_Code],5),
	SourceProviderTaxId	= left([Provider_Tax_ID],9),
	ProviderCheckNumber = null,
	ProviderCheckDate = null,
	ProviderCheckAmount = [Final_Allowance],
	AttachmentInfo = null,
	Is_Duplicate = 0,
	ReviewedState = [Review_State_Bill],
	Patient_Account = null
--into _Temp
From
	SJHeader b					
where ISNULL(missingData,0) = 0
and b.claimbillid not in (select id from [QA_INTM_ReviewWare]..claim_Bill cb)
and /*'AR' +*/ [Bill_ID] + '-01' not in (select accountnumber from [QA_INTM_ReviewWare]..claim_bill where accountnumber like 'GSRMA%')
;


--  select count(*) from AMLBillHeader where isnull(missingdata,0) = 0

insert into [QA_INTM_ReviewWare]..claim_bill_ext (claim_bill_id) 
select ID from [QA_INTM_ReviewWare]..CLAIM_BILL cb (nolock) 
where ID not in (select claim_bill_id from [QA_INTM_ReviewWare]..claim_bill_ext);
	
	
set identity_insert [QA_INTM_ReviewWare]..CLAIM_BILL OFF;

--update statistics [QA_INTM_ReviewWare]..claim_bill;

commit
rollback