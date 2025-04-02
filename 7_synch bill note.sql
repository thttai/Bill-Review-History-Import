-- ===================
-- Generate BILL NOTE
-- ===================

-- delete from [QA_INTM_ReviewWare]..CLAIM_BILL_NOTE
begin transaction;
with cte (BillId, Note) as
(
Select
ClaimBillId,
Note = 
'BillType: ' + isnull(convert(varchar,[BillTypeCode], 101), '') + '
PPO Network: ' + isnull([PpoNetwork], '') 
From
	TempBillHeader where ISNULL(missingdata,0) = 0				
	and claimbillid in (select id from [QA_INTM_ReviewWare]..claim_bill)
)
insert into [QA_INTM_ReviewWare]..Claim_Bill_Note (ID, Date, Claim_Bill_ID, IsLocked, Notes, UUID)
select BillId, GETDATE(), BillId, 1, Note, 'dbo' from cte

commit;
rollback;

-- VALIDATING DATA
select top 1000 c.client_ID, c.claimno, cb.* from [QA_INTM_ReviewWare]..claim_bill cb
	join [QA_INTM_ReviewWare]..CLAIM c on c.ID = cb.claim_id
	where batch_ID = -1;
	
select top 1000 cbl.* from [QA_INTM_ReviewWare]..claim_bill_line cbl
	join [QA_INTM_ReviewWare]..CLAIM_BILL cb on cb.ID = cbl.Claim_Bill_ID
	where Batch_ID = -11

begin transaction	
update [QA_INTM_ReviewWare]..claim_bill_line set units = units / 100
from [QA_INTM_ReviewWare]..claim_bill_line cbl
	join [QA_INTM_ReviewWare]..CLAIM_BILL cb on cb.ID = cbl.Claim_Bill_ID
	where Batch_ID in (-9,-10)


commit
	
select COUNT(*) from TempBillHeader;
select * from TempBillDetail;


select 
Claim_Number, Claimant_Name, Review_Number, SSN, DateOfBirth, Injury_Date, Charge, Allowance, ICD9Code, BillTypeCode, FirstDateofService, LastDateofService, InsurerRecDate, DateOfBill, DateCorVelRecBill, DateCorVelEnteredBill, ReferringPhysicianName, TaxID, Provider_Name, Billing_Provider_Address1, PracticeCity, PracticeState, Billing_Provider_Zip
from TempBillHeader where missingdata=1




-- ARCHIVE IMPORTED TABLE

select * into SJHeader_History from TempBillHeader
select * into SJDetail_History from TempBillDetail