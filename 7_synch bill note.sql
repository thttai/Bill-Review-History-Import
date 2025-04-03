USE [QA_INTM_Temp4Dts]
GO

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

IF @@ERROR = 0  
    COMMIT;  
ELSE  
    ROLLBACK;

-- VALIDATING DATA
declare @BatchId int = -18;
with cteTemp as (
select 
    BillNumber, Allowed = sum(convert(decimal(18,2),allowed)) from [qa_intm_temp4dts].[dbo].[TempBillDetail]
group by BillNumber
)
,cteBill as (
select 
    BillNumber=accountnumber, edi_source_control_number, totalAllowed from QA_INTM_REVIEWWARE..CLAIM_BILL (nolock) where batch_id = @BatchId
)
,cteBillLine as (
select 
    BillNumber=accountnumber, cb.edi_source_control_number, totalAllowed = sum(finalallowance)
from 
    QA_INTM_REVIEWWARE..CLAIM_BILL cb (nolock) 
join 
    QA_INTM_REVIEWWARE..CLAIM_BILL_LINE cbl (nolock) on cbl.claim_bill_id = cb.id
where 
    batch_id = @BatchId
group by 
    accountnumber, cb.edi_source_control_number
)
select 
    t.BillNumber
    ,TempAllow = t.Allowed
    ,BillAllow = b.TotalAllowed
    ,BillLineAllow = bl.TotalAllowed
From
    cteTemp t
left Join
    cteBill b on b.Edi_Source_Control_Number = t.BillNumber
Left Join
    cteBillLine bl on bl.edi_source_control_number = t.BillNumber
WHERE 
    t.Allowed != b.totalAllowed 
    OR t.Allowed != bl.totalAllowed 
    OR b.totalAllowed != bl.totalAllowed
Order by
    b.BillNumber



select top 1000 c.client_ID, c.claimno, cb.* from [QA_INTM_ReviewWare]..claim_bill cb
	join [QA_INTM_ReviewWare]..CLAIM c on c.ID = cb.claim_id
	where batch_ID = -18;
	
select top 1000 cbl.* from [QA_INTM_ReviewWare]..claim_bill_line cbl
	join [QA_INTM_ReviewWare]..CLAIM_BILL cb on cb.ID = cbl.Claim_Bill_ID
	where Batch_ID = -18

begin transaction	
update [QA_INTM_ReviewWare]..claim_bill_line set units = units / 100
from [QA_INTM_ReviewWare]..claim_bill_line cbl
	join [QA_INTM_ReviewWare]..CLAIM_BILL cb on cb.ID = cbl.Claim_Bill_ID
	where Batch_ID in (-9,-10)


commit

-- ARCHIVE IMPORTED TABLE

select * into SJHeader_History from TempBillHeader
select * into SJDetail_History from TempBillDetail