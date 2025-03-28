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
	bl.[Bill_ID] + convert(varchar,[Bill_ID_Sequence_ID])
	,b.claimbillid
	,convert(int,[Bill_ID_Sequence_ID])--LineNumber
	,[Date_of_Service]
	,left([Original_Procedure_Code],11)
	,[Original_Procedure_Code]
	,[Modifier_1]
	,[Modifier2]
	,Units = convert(money,[Quantity_of_service])
	,convert(money,bl.[Charges])
	,convert(money,[Allowance])
	,PlaceOfServiceCode = null
	,null
	,null
	,[Review_Reduction_Code_01]
	,convert(money,bl.[PPOSavings])+convert(money,[Allowance])
	,convert(money,bl.[PPOSavings])+convert(money,[Allowance])
	,left(bl.[ICD9_code_1] ,10)
	,DaysSupplied = null
	,convert(money,bl.[PPOSavings])
From SJDetail bl
Join
	SJHeader b on b.[Bill_ID] = bl.[Bill_ID]  and isnull(missingdata,0)=0
where ISNULL(missingData,0) = 0
and b.claimbillid in (select id from [QA_INTM_ReviewWare]..claim_bill)
;

--select TotalCharges, TotalAllowed,* from [QA_INTM_ReviewWare]..CLAIM_BILL cb (nolock) where ID = -54040
--select COUNT(*) from SJDetail

--update statistics [QA_INTM_ReviewWare]..claim_bill_line;

commit;
rollback