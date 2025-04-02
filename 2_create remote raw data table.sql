USE [QA_INTM_Temp4Dts]
GO

-- select count(*) from Medata_EXTRACT;

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
    ,ClaimNumber        =    rtrim(ClaimID)
    ,Line_Sequence_no    =    convert(bigint,CustomerLineNumber)
    ,BillIDSequenceID = BillIDSequenceID
    ,ReviewReductionCode01 = TRIM(ReviewReductionCode01)
    ,StateCode = Case When StateCode1 like '00%' then '' else RTRIM(STateCode1) end
    + Case When StateCode2 like '00%' then '' else ',' + RTRIM(STateCode2) end
    + Case When StateCode3 like '00%' then '' else ',' + RTRIM(STateCode3) end
    + Case When StateCode4 like '00%' then '' else ',' + RTRIM(STateCode4) end
    + Case When StateCode5 like '00%' then '' else ',' + RTRIM(StateCode5) end
    + Case When StateCode6 like '00%' then '' else ',' + RTRIM(StateCode6) end
--into MedDataBillDetail    
from
    Medata_EXTRACT

--if OBJECT_ID('[viewMedataSiaLwpBillHeader]') > 0 drop view [viewMedataSiaLwpBillHeader]; 
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
    ,DateOfServiceFrom        =    case when ISDATE(BOSDate) = 1 then convert(datetime,BOSDate) else null end
    ,DateOfServiceTo        =    case when ISDATE(EOSDate) = 1 then convert(datetime,EOSDate) else null end
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
    Medata_EXTRACT
)