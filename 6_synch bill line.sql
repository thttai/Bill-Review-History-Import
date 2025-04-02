-- BILL LINE
begin transaction
insert into [QA_INTM_ReviewWare]..CLAIM_BILL_LINE 
(
	EdiSourceControlNumber,
	Claim_Bill_ID,
	Line_Sequence_no,
	DateOfService, 
	Billed_Code,
	CPTCode, 
	MOD,--Modifier, 
	Modifier2,
	Units, 
	Charges,--ActualCharge, 
	FinalAllowance,--RecommendedPayment, 
	--ReasonCode, 
	Place_of_Service,--PlaceOfServiceCode, 
	--StateDXR, 
	--NDC, 
	CPTCodeDesc--DrugDescription, 
	--QuantityDispensed, 
	--QuantityAllowed, 
	--Comments, 
	--Filler, 
	--CorVelSiteCode, 
	--Filler2, 
	--Review_Number, 
	--CorVelBillSequence, 
	--Date_Printed
	,AdditionalNote
	,EOB
	,Allowed
	,FeeSchedule
	,Icd91
	,RxDaysSupply
	,ppodiscount
)
select
	bl.[BillNumber] + convert(varchar,[BillIDSequenceID])
	,b.claimbillid
	,convert(int,[BillIDSequenceID])--LineNumber
	,[DateofService]
	,left([Billed_Code],11)
	,[Billed_Code]
	,[Modifier1]
	,[Modifier2]
	,Units = convert(money,[Units])
	,convert(money,bl.[Charges])
	,convert(money,[Allowed])
	,PlaceOfServiceCode = null
	,null
	,null
	,[ReviewReductionCode01]
	,convert(money,bl.[PPODiscount])+convert(money,[Allowed])
	,convert(money,bl.[PPODiscount])+convert(money,[Allowed])
	,left(bl.[ICD9code1] ,10)
	,DaysSupplied = null
	,convert(money,bl.[PPODiscount])
From TempBillDetail bl
Join
	TempBillHeader b on b.[BillNumber] = bl.[BillNumber]  and isnull(missingdata,0)=0
where ISNULL(missingData,0) = 0
and b.claimbillid in (select id from [QA_INTM_ReviewWare]..claim_bill)
;

--select TotalCharges, TotalAllowed,* from [QA_INTM_ReviewWare]..CLAIM_BILL cb (nolock) where ID = -54040
--select COUNT(*) from SJDetail

--update statistics [QA_INTM_ReviewWare]..claim_bill_line;

commit;
rollback