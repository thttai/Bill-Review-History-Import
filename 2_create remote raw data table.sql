USE [QA_INTM_Temp4Dts]
GO

/****** Object:  Table [dbo].[intmco_paycode]    Script Date: 3/28/2025 3:24:29 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Medata_LAWA_BIG_EXTRACT_20170401_20250228](
	[LineID] [int] NOT NULL,
	[AdjustmentReasonCode] [nvarchar](max) NULL,
	[AdjustorID] [nvarchar](max) NULL,
	[AdmissionDate] [nvarchar](max) NULL,
	[AnesthesiaMinutes] [nvarchar](max) NULL,
	[AnesthesiaTime] [nvarchar](max) NULL,
	[BillID] [nvarchar](max) NULL,
	[BillIDDate] [nvarchar](max) NULL,
	[BillIDSequenceID] [nvarchar](max) NULL,
	[BillTypeCode] [nvarchar](max) NULL,
	[BOSDate] [nvarchar](max) NULL,
	[Charges] [nvarchar](max) NULL,
	[ClaimID] [nvarchar](max) NULL,
	[ClaimantDateofBirth] [nvarchar](max) NULL,
	[ClaimantDateofInjury] [nvarchar](max) NULL,
	[ClaimantFirstName] [nvarchar](max) NULL,
	[ClaimantGender] [nvarchar](max) NULL,
	[ClaimantLastName] [nvarchar](max) NULL,
	[ClaimantMI] [nvarchar](max) NULL,
	[ClaimantSSN] [nvarchar](max) NULL,
	[ClientAddress1] [nvarchar](max) NULL,
	[ClientAddress2] [nvarchar](max) NULL,
	[ClientCity] [nvarchar](max) NULL,
	[ClientID] [nvarchar](max) NULL,
	[ClientName] [nvarchar](max) NULL,
	[ClientState] [nvarchar](max) NULL,
	[ClientZipCode] [nvarchar](max) NULL,
	[CoPay] [nvarchar](max) NULL,
	[CustomerLineNumber] [nvarchar](max) NULL,
	[DateBilled] [nvarchar](max) NULL,
	[DateofService] [nvarchar](max) NULL,
	[DatePaid] [nvarchar](max) NULL,
	[DateReceived1] [nvarchar](max) NULL,
	[DateReceived2] [nvarchar](max) NULL,
	[DateReceived3] [nvarchar](max) NULL,
	[Deductible] [nvarchar](max) NULL,
	[DischargeStatus] [nvarchar](max) NULL,
	[Discounts] [nvarchar](max) NULL,
	[DRGCode] [nvarchar](max) NULL,
	[EOSDate] [nvarchar](max) NULL,
	[ICD9code1] [nvarchar](max) NULL,
	[ICD9code2] [nvarchar](max) NULL,
	[ICD9code3] [nvarchar](max) NULL,
	[ICD9code4] [nvarchar](max) NULL,
	[InsuredCorpAddress1] [nvarchar](max) NULL,
	[InsuredCorpAddress2] [nvarchar](max) NULL,
	[InsuredCorpCity] [nvarchar](max) NULL,
	[InsuredCorpName] [nvarchar](max) NULL,
	[InsuredCorpState] [nvarchar](max) NULL,
	[InsuredCorpZipCode] [nvarchar](max) NULL,
	[InsuredCorporationID] [nvarchar](max) NULL,
	[IPOPFlag] [nvarchar](max) NULL,
	[Modifier1] [nvarchar](max) NULL,
	[Modifier2] [nvarchar](max) NULL,
	[NumberDone] [nvarchar](max) NULL,
	[OriginalProcedureCode] [nvarchar](max) NULL,
	[PatientAccountID] [nvarchar](max) NULL,
	[PaymentKindCode] [nvarchar](max) NULL,
	[Penalties] [nvarchar](max) NULL,
	[POS] [nvarchar](max) NULL,
	[PPOID] [nvarchar](max) NULL,
	[PPOReduction] [nvarchar](max) NULL,
	[ProcedureCodeorServiceCode] [nvarchar](max) NULL,
	[ProcedureCodeorServiceCode2] [nvarchar](max) NULL,
	[ProviderAddress1] [nvarchar](max) NULL,
	[ProviderAddress2] [nvarchar](max) NULL,
	[ProviderCity] [nvarchar](max) NULL,
	[ProviderFirstName] [nvarchar](max) NULL,
	[ProviderID] [nvarchar](max) NULL,
	[ProviderLastName] [nvarchar](max) NULL,
	[ProviderMI] [nvarchar](max) NULL,
	[ProviderSpecialty] [nvarchar](max) NULL,
	[ProviderState] [nvarchar](max) NULL,
	[ProviderTaxID] [nvarchar](max) NULL,
	[ProviderType] [nvarchar](max) NULL,
	[ProviderZipCode] [nvarchar](max) NULL,
	[RecommendedAllowance] [nvarchar](max) NULL,
	[ReviewReductions] [nvarchar](max) NULL,
	[ReviewStateClaim] [nvarchar](max) NULL,
	[StateCode1] [nvarchar](max) NULL,
	[StateCode2] [nvarchar](max) NULL,
	[StateCode3] [nvarchar](max) NULL,
	[StateCode4] [nvarchar](max) NULL,
	[StateCode5] [nvarchar](max) NULL,
	[StateCode6] [nvarchar](max) NULL,
	[Taxes] [nvarchar](max) NULL,
	[TOS] [nvarchar](max) NULL,
	[UBRevenueCode] [nvarchar](max) NULL,
	[Undercharges] [nvarchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO


