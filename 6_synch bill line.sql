USE [QA_INTM_Temp4Dts]
GO

-- BILL LINE

-- debug
SELECT top 10 EdiSourceControlNumber,
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
	From [INTM_ReviewWare]..CLAIM_BILL_LINE order by ID desc;

begin transaction;
begin transaction
insert into [INTM_ReviewWare]..CLAIM_BILL_LINE 
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
	,left(b.[ICD9code1] ,10)
	,DaysSupplied = null
	,convert(money,bl.[PPODiscount])
From TempBillDetail bl
Join
	TempBillHeader b on b.[BillNumber] = bl.[BillNumber]  and isnull(missingdata,0)=0
where ISNULL(missingData,0) = 0
and b.claimbillid in (select id from [INTM_ReviewWare]..claim_bill);

IF @@ERROR = 0  
    COMMIT;  
ELSE  
    ROLLBACK;