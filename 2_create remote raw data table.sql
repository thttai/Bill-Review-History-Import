USE [QA_INTM_Temp4Dts]
GO

-- select count(*) from Medata_EXTRACT;

-- drop view
-- if OBJECT_ID('[vwMedataLawaBillDetail]') > 0 drop view [vwMedataLawaBillDetail]; 

CREATE View [dbo].[vwMedataLawaBillDetail] as
with cte(Value) as (
    SELECT 
        [Column 0] as Value
    FROM [BIG_EXTRACT_20170401-20250228_byclmlst]
)
select --top 100
    DateofService        =    case when isdate(TRIM(SUBSTRING(Value, 9, 8))) = 1 then convert(datetime,TRIM(SUBSTRING(Value, 9, 8)))    else null end	-- Date of Service,8,DT,No description available,9,16
    ,CptCode            =    replace(TRIM(SUBSTRING(Value, 17, 17)),'-','')	-- Procedure Code or Service Code,17,AN,"Valid CPT NDC or Fee Schedule code",017,033
    ,Modifier1            =    case when TRIM(SUBSTRING(Value, 34, 2)) = '00' then null else TRIM(SUBSTRING(Value, 34, 2)) end	-- Modifier 1,2,AN,Valid modifier for state and type.,34,35
    ,Modifier2            =    case when TRIM(SUBSTRING(Value, 36, 2)) = '00' then null else TRIM(SUBSTRING(Value, 36, 2)) end	-- Modifier 2,2,AN,Valid modifier for state and type.,36,37

    ,PlaceOfService    =    TRIM(SUBSTRING(Value, 38, 4))	-- POS,4,DV,Place of Service code.  See Appendix I,38,41
    ,Units                    =    TRIM(SUBSTRING(Value, 52, 3))	-- Number Done,3,N3,Quantity of service,52,54
    ,Charges	=	TRIM(SUBSTRING(Value, 55, 12))	-- Charges,12,SN9.2,Provider's charge for service,55,66
    ,ReviewReductions	=	TRIM(SUBSTRING(Value, 67, 12))	-- Review Reductions,12,SN9.2,,67,78
    ,Allowed    =    TRIM(SUBSTRING(Value, 151, 12))	-- Recommended Allowance,12,SN9.2,,151,162
    ,PPODiscount        =    TRIM(SUBSTRING(Value, 229, 12))	-- PPO Reduction,12,SN9.2,,229,240
    ,Billed_Code        =    replace(TRIM(SUBSTRING(Value, 2361, 17)),'-','')	-- Original Procedure Code,17,AN,"Original submitted procedure code",2361,2377
    ,RevenueCode        =    TRIM(SUBSTRING(Value, 2735, 4))	-- UB Revenue Code,4,DV,"Hospital's UB Revenue Code",2735,2738
    ,BillNumber        = 	TRIM(SUBSTRING(Value, 360, 22))	-- Bill ID,22,AN,"System Assigned Bill Review Identifier, Format: {CCYYMMDDHHmmSShh}{User}{Suffix}",360,381
    ,ClaimNumber        =    TRIM(SUBSTRING(Value, 241, 30))	-- Claim ID,30,AN,No description available,241,270
    ,Line_Sequence_no    =    convert(bigint,TRIM(SUBSTRING(Value, 2520, 10)))	-- Customer Line Number,10,N10,"Medata Customer's Detail Line Number corresponding to 'Medata Customer's Bill ID'   in position 2331 above.",2520,2529
    ,BillIDSequenceID = TRIM(SUBSTRING(Value, 2196, 6))	-- Bill ID Sequence ID,6,N6,Sequential number for each detail line,2196,2201
    ,ReviewReductionCode01 = TRIM(SUBSTRING(Value, 163, 2))	-- Review Reduction Code 01,2,DV,"First Reduction Reason Code applied to this detail line.",163,164
    ,StateCode = Case When TRIM(SUBSTRING(Value, 2779, 4)) like '00%' then '' else RTRIM(TRIM(SUBSTRING(Value, 2779, 4))) end	-- State Code1,4,DV,"Review State specific reason code. Medata RC1 translated into State Code1.",2779,2782
    + Case When TRIM(SUBSTRING(Value, 2783, 4)) like '00%' then '' else ',' + RTRIM(TRIM(SUBSTRING(Value, 2783, 4))) end	-- State Code2,4,DV,"Review State specific reason code. Medata RC2 translated into State Code2.",2783,2786
    + Case When TRIM(SUBSTRING(Value, 2787, 4)) like '00%' then '' else ',' + RTRIM(TRIM(SUBSTRING(Value, 2787, 4))) end	-- State Code3,4,DV,"Review State specific reason code. Medata RC3 translated into State Code3.",2787,2790
    + Case When TRIM(SUBSTRING(Value, 2791, 4)) like '00%' then '' else ',' + RTRIM(TRIM(SUBSTRING(Value, 2791, 4))) end	-- State Code4,4,DV,"Review State specific reason code. Medata RC4 translated into State Code4.",2791,2794
    + Case When TRIM(SUBSTRING(Value, 2795, 4)) like '00%' then '' else ',' + RTRIM(TRIM(SUBSTRING(Value, 2795, 4))) end	-- State Code5,4,DV,"Review State specific reason code. Medata RC5 translated into State Code5.",2795,2798
    + Case When TRIM(SUBSTRING(Value, 2799, 4)) like '00%' then '' else ',' + RTRIM(TRIM(SUBSTRING(Value, 2799, 4))) end	-- State Code6,4,DV,"Review State specific reason code. Medata RC6 translated into State Code6.",2799,2802
--into MedDataBillDetail    
from cte;

select BillNumber, ClaimNumber, count(*) from [dbo].[vwMedataLawaBillDetail] group by BillNumber, ClaimNumber;
-- select top 100 * from [dbo].[vwMedataLawaBillDetail];


-- if OBJECT_ID('[vwMedataLawaBillHeader]') > 0 drop view [vwMedataLawaBillHeader]; 
GO

CREATE View [vwMedataLawaBillHeader] as
with cte(Value) as (
    SELECT 
        [Column 0] as Value
    FROM [BIG_EXTRACT_20170401-20250228_byclmlst]
)
Select distinct --top 10
    BillDateInserted    =    convert(Datetime,TRIM(SUBSTRING(Value, 1, 8)))	-- Bill ID Date,8,DT,"Calendar Date of the Bill ID, or the date the bill was first entered and reviewed",1,8

    --,PlaceOfService    =    rtrim(POS)
    
    ,ClaimNumber        =    TRIM(SUBSTRING(Value, 241, 30))	-- Claim ID,30,AN,No description available,241,270
    ,BillNumber        = TRIM(SUBSTRING(Value, 360, 22))	-- Bill ID,22,AN,"System Assigned Bill Review Identifier, Format: {CCYYMMDDHHmmSShh}{User}{Suffix}",360,381
    ,ICD9code1        = TRIM(SUBSTRING(Value, 382, 6))	-- ICD9 code 1,6,DV,First Valid ICD-9 code,382,387
    ,ICD9code2        = TRIM(SUBSTRING(Value, 388, 6))	-- ICD9 code 2,6,DV,Second Valid ICD-9 code,388,393
    ,ICD9code3        = TRIM(SUBSTRING(Value, 394, 6))	-- ICD9 code 3,6,DV,Third Valid ICD9-9 code,394,399
    ,ICD9code4        = TRIM(SUBSTRING(Value, 400, 6))	-- ICD9 code 4,6,DV,Fourth Valid ICD-9 code,400,405
    ,PpoNetwork        =    RTRIM(TRIM(SUBSTRING(Value, 406, 10)))	-- PPO ID,10,AN,PPO Vendor Identifier,406,415
    ,Provider_Bill_Date        = case when convert(int,TRIM(SUBSTRING(Value, 416, 8))) > 0 then convert(datetime,TRIM(SUBSTRING(Value, 416, 8)))    else null end	-- Date Billed,8,DT,"Date provider submitted medical billing",416,423
    ,BrReceivedDate            = case when convert(int,TRIM(SUBSTRING(Value, 424, 8))) > 0 then convert(datetime,TRIM(SUBSTRING(Value, 424, 8)))   else null end	-- Date Received 1,8,DT,Date customer received medical billing,424,431
    ,ProviderCheckDate        = case when convert(int,TRIM(SUBSTRING(Value, 448, 8))) > 0 then convert(datetime,TRIM(SUBSTRING(Value, 448, 8)))   else null end	-- Date Paid,8,DT,Date of payment,448,455
    ,ProviderID        =    TRIM(SUBSTRING(Value, 466, 18))	-- Provider ID,18,AN,No description available,466,483
    ,ProviderTaxID        =    REPLACE(TRIM(SUBSTRING(Value, 484, 11)),'-','')	-- Provider Tax ID,11,AN,No description available,484,494
    ,ProviderLastName        = TRIM(SUBSTRING(Value, 495, 30))	-- Provider Last Name,30,AN,No description available,495,524
    ,ProviderFirstName        = TRIM(SUBSTRING(Value, 525, 20))	-- Provider First Name,20,AN,No description available,525,544
    ,ProviderMI        = TRIM(SUBSTRING(Value, 545, 1))	-- Provider MI,1,AN,No description available,545,545
    ,ProviderAddress1        = TRIM(SUBSTRING(Value, 546, 30))	-- Provider Address 1,30,AN,No description available,546,575
    ,ProviderAddress2        = TRIM(SUBSTRING(Value, 576, 30))	-- Provider Address 2,30,AN,No description available,576,605
    ,ProviderCity        = TRIM(SUBSTRING(Value, 606, 20))	-- Provider City,20,AN,No description available,606,625
    ,ProviderState        = TRIM(SUBSTRING(Value, 626, 2))	-- Provider State,2,DV,No description available,626,627
    ,ProviderZipCode    =    TRIM(SUBSTRING(Value, 628, 10))	-- Provider Zip Code,10,AN,No description available,628,637
    ,ReviewedState = TRIM(SUBSTRING(Value, 927, 2))	-- Review State Claim,2,DV,"Valid 2 character Postal State code (i.e. CA) presently set in bill review's Claim.",927,928
    ,AdjustmentReasonCode    = case when TRIM(SUBSTRING(Value, 1737, 3)) in ('000') then null else TRIM(SUBSTRING(Value, 1737, 3)) end	-- Adjustment Reason Code,3,DV,"derived from customer's Adjustment Reason Code file utilized at time of performing Adjust A Bill",1737,1739
    ,UB92_Billed_DRG_No        = case when TRIM(SUBSTRING(Value, 1740, 3)) in ('000') then null else TRIM(SUBSTRING(Value, 1740, 3)) end    -- DRG Code,3,N3,"DRG Code used in reviewing Hospital bill",1740,1742
    ,UB92_Admit_Date        =    case when convert(int,TRIM(SUBSTRING(Value, 2234, 8))) > 0 then convert(datetime,TRIM(SUBSTRING(Value, 2234, 8))) else null end    -- Admission Date,8,DT,"Claimant's Admission Date (Hospital bills)",2234,2241
    ,DateOfServiceFrom        =    case when convert(int,TRIM(SUBSTRING(Value, 2242, 8))) > 0 then convert(datetime,TRIM(SUBSTRING(Value, 2242, 8))) else null end    -- BOS Date,8,DT,"Claimant's Beginning Date of Service",2242,2249
    ,DateOfServiceTo        =    case when convert(int,TRIM(SUBSTRING(Value, 2250, 8))) > 0 then convert(datetime,TRIM(SUBSTRING(Value, 2250, 8))) else null end    -- EOS Date,8,DT,"Claimant's Ending Date of Service",2250,2257
    ,BillTypeCode            =    TRIM(SUBSTRING(Value, 2258, 3))    -- Bill Type Code,3,DV,"Valid Bill Type code.  See Appendix VI",2258,2260
    --,HospitalBillFlag            -- select distinct HospitalBillFlag from meddatacwall
    ,FormType                =    case when TRIM(SUBSTRING(Value, 1163, 2)) in ('IP', 'OP') then 'UB04' else 'HCFA' end	-- IPOP Flag,2,DV,"IP - Inpatient billing OP - Outpatient billing {space filled} - non-facility billing",1163,1164
    ,UB92_Discharge_Status    =    TRIM(SUBSTRING(Value, 2262, 2))        -- Discharge Status,2,DV,"Valid Hospital Discharge Status code.",2262,2263
    ,Provider_Patient_Account_Number    =    TRIM(SUBSTRING(Value, 2315, 20))	-- Patient Account ID,20,AN,"Provider's patient account identifier",2315,2334
    ,ClaimantLastName = TRIM(SUBSTRING(Value, 271, 30))	-- Claimant Last Name,30,AN,No description available,271,300
    ,ClaimantFirstName = TRIM(SUBSTRING(Value, 301, 20))	-- Claimant First Name,20,AN,No description available,301,320
    ,ClaimantDateofInjury = convert(datetime,TRIM(SUBSTRING(Value, 333, 8)))	-- Claimant Date of Injury,8,DT,No description available,333,340
    ,ClaimantDateofBirth = convert(datetime,TRIM(SUBSTRING(Value, 341, 8)))	-- Claimant Date of Birth,8,DT,No description available,341,348
From cte;

select count(*) from [dbo].[vwMedataLawaBillHeader];
-- select top 100 * from [dbo].[vwMedataLawaBillHeader];
-- -- check if there is any field of first 10 rows does equal between viewMedataSiaLwpBillHeader and vwMedataLawaBillHeader
-- with h1 as (select top 10 * from [viewMedataSiaLwpBillHeader]), h2 as (select top 10 * from [vwMedataLawaBillHeader])
-- select
--     h1.BillDateInserted, h2.BillDateInserted,
--     h1.ClaimNumber, h2.ClaimNumber,
--     h1.BillNumber, h2.BillNumber,
--     h1.ICD9code1, h2.ICD9code1,
--     h1.ICD9code2, h2.ICD9code2,
--     h1.ICD9code3, h2.ICD9code3,
--     h1.ICD9code4, h2.ICD9code4,
--     h1.PpoNetwork, h2.PpoNetwork,
--     h1.Provider_Bill_Date, h2.Provider_Bill_Date,
--     h1.BrReceivedDate, h2.BrReceivedDate
-- from h1
-- inner join h2 on h1.BillNumber = h2.BillNumber
-- where
--     h1.BillDateInserted != h2.BillDateInserted
--     or h1.ClaimNumber != h2.ClaimNumber
--     or h1.BillNumber != h2.BillNumber
--     or h1.ICD9code1 != h2.ICD9code1
--     or h1.ICD9code2 != h2.ICD9code2
--     or h1.ICD9code3 != h2.ICD9code3
--     or h1.ICD9code4 != h2.ICD9code4
--     or h1.PpoNetwork != h2.PpoNetwork
--     or h1.Provider_Bill_Date != h2.Provider_Bill_Date
--     or h1.BrReceivedDate != h2.BrReceivedDate