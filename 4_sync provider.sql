/*******************************************************************************
* Bill Review History Import Script
* Purpose: Parse fixed-width bill data into structured SQL tables
* Process: Import column definitions → Import bill data → Parse fields → Create views
*******************************************************************************/

USE [QA_INTM_Temp4Dts]
GO

-- debug
--select top 10 * from [vwTempMedataBillDetail];
--select top 10 * from [vwTempMedataBillHeader];
--select count(*) from [vwTempMedataBillDetail];
--select count(*) from [vwTempMedataBillHeader];


if OBJECT_ID('TempBillHeader') > 0 drop table TempBillHeader; 
if OBJECT_ID('TempBillDetail') > 0 drop table TempBillDetail; 

-- create tables from views
SELECT *
INTO TempBillDetail
FROM [vwTempMedataBillDetail];

SELECT *
INTO TempBillHeader
FROM [vwTempMedataBillHeader];

-- debug
-- select count(*) from vwTempMedataBillDetail;
-- select count(*) from TempBillDetail;
-- select count(*) from vwTempMedataBillHeader;
-- select count(*) from TempBillHeader;
-- select top 1000 ClaimNumber, RIGHT(claimnumber,6), SUBSTRING(claimnumber,7, len(claimnumber) - 5) from TempBillHeader ;


------------------
-- SYNCH PROVIDER
------------------

-- check to create CorvelProvider
if OBJECT_ID('dbo.CorvelProvider', 'U') IS NULL
begin
create table CorvelProvider (
    ID INT IDENTITY PRIMARY KEY,      -- Unique identifier
    TaxId VARCHAR(11),
    ProviderName VARCHAR(100),
    LastName VARCHAR(30),
    FirstName VARCHAR(20),
    PracticeAddress VARCHAR(100),
	PracticeAddress2 VARCHAR(100),
	PracticeCity VARCHAR(100),
	PracticeState VARCHAR(100),
	PracticeZip VARCHAR(100),
	BrPostFixTaxId VARCHAR(100),
	IsNew INT DEFAULT 1,
);
-- Create index after table creation
CREATE INDEX IX1_CorvelProvider 
ON dbo.CorvelProvider (ProviderName, PracticeAddress, TaxId);
end

-- mark not new for current CorvelProvider
update CorvelProvider set isnew = 0;

-- debug
-- select top 10 * from CorvelProvider
-- delete from CorvelProvider

-- insert into CorvelProvider
begin transaction
insert into CorvelProvider
(ProviderName, PracticeAddress, PracticeAddress2,
PracticeCity, PracticeState, PracticeZip, TaxID)
SELECT Distinct
left(h.ProviderFirstName + ' ' + h.ProviderLAstNAme,100) as ProviderName, 
left(h.ProviderAddress1,50) as PracticeAddress, 
left(h.ProviderAddress2,50) as PracticeAddress2,
left(h.ProviderCity,15) as PracticeCity, left(h.ProviderState,2) as PracticeState, 
left(h.ProviderZipCode,5) as PracticeZip, left(h.ProviderTaxID,9) as TaxID
--,ProviderLicenseNumber -- dont get the license else too many dup return
--into CorvelProvider
from TempBillHeader h 
left join CorvelProvider p on h.ProviderFirstName + ' ' + h.ProviderLAstNAme = p.providerNAme and h.ProviderAddress1 = p.PracticeAddress and h.ProviderTaxID = p.TaxId
where p.providername is null
--order by 1
select * from corvelprovider where  BrPostFixTaxId is null

IF @@ERROR = 0  
    COMMIT;  
ELSE  
    ROLLBACK;

-- debug, find null TaxId
select * from CorvelProvider where TaxId is null OR TaxId = '';


-- Generate TAXID postfix from BR
update CorvelProvider set
	BrPostFixTaxId = [dbo].[fnGet2csProviderTaxIdExt](TaxId, null)
Where isnew = 1;

-- debug, get all records from CorvelProvider
select * from CorvelProvider where TaxId = '270276119';
--select COUNT(*) from Provider where LEFT(taxid,9) = '270276119';


-- Due to dup taxid, reindex the postfix again
with cte (id, taxid, TaxidCounter) as
( 
select ID, TaxID, row_number() over (partition by taxid order by id) from CorvelProvider where isnew = 1
) 
update CorvelProvider set 
-- select *,
	BrPostFixTaxId = right('000' + convert(varchar,convert(int,BrPostFixTaxId) + cte.TaxIdCounter - 1),4)
from CorvelProvider p
join cte on cte.id = p.id
where isnew = 1
;

-- debug
--select * from CorvelProvider where IsNew = 1 order by BrPostFixTaxId desc;
---- add colum ProviderLicenseNumber and update data from TempBillHeader
--Alter Table CorvelProvider add  ProviderLicenseNumber varchar(30);
--update CorvelProvider set p.ProviderLicenseNumber = h.ProviderLicenseNumber 
--from TempBillHeader h join CorvelProvider p on h.ProviderFirstName + ' ' + h.ProviderLAstNAme = p.providerNAme and h.ProviderTaxID = p.TaxId
--where p.isnew =1;

--select top 10 ID, StateLicenseNo, PracticeName, PracticeName, BillingAddress1, BillingCity, BillingState, BillingZip, ContactAddress1, ContactCity, ContactState, ContactZip, TaxId from PROVIDER;
--select providerNAme, ProviderLicenseNumber, TaxId, isnew from CorvelProvider;

-- debug: create table PROVIDER
-- if OBJECT_ID('dbo.PROVIDER', 'U') IS NULL
-- begin
-- create table PROVIDER (
--     ID INT IDENTITY PRIMARY KEY,      -- Unique identifier
--     StateLicenseNo VARCHAR(10),       -- State License Number
--     PracticeName VARCHAR(160),        -- Practice Name
--     BillingAddress1 VARCHAR(50),      -- Billing Address 1
--     BillingCity VARCHAR(15),          -- Billing City
--     BillingState VARCHAR(2),          -- Billing State
--     BillingZip VARCHAR(5),            -- Billing Zip
--     ContactAddress1 VARCHAR(50),      -- Contact Address 1
--     ContactCity VARCHAR(15),          -- Contact City
--     ContactState VARCHAR(2),          -- Contact State
--     ContactZip VARCHAR(5),            -- Contact Zip
--     TaxId VARCHAR(17),                -- Federal Tax ID (with postfix)
--     Status INT,                       -- Status (0 = Inactive, 1 = Active, 9 = New)
--     SameAsContact INT,                -- Same as Contact (0 = No, 1 = Yes)
-- );
-- end


BEGIN TRANSACTION;
ALTER TABLE PROVIDER DISABLE TRIGGER ALL;
INSERT INTO PROVIDER (
    StateLicenseNo, 
    PracticeName, 
    BillingAddress1, 
    BillingCity, 
    BillingState, 
    BillingZip, 
    ContactAddress1, 
    ContactCity, 
    ContactState, 
    ContactZip,
    TaxId,
    Status,
    SameAsContact
)
SELECT 
    LEFT(ProviderLicenseNumber, 10), 
    LEFT(ProviderName, 160), 
    LEFT(PracticeAddress, 50), 
    PracticeCity, 
    PracticeState, 
    PracticeZip, 
    LEFT(PracticeAddress, 50), 
    PracticeCity, 
    PracticeState, 
    PracticeZip, 
    CONVERT(VARCHAR, TaxId) + '-' + ISNULL(BrPostFixTaxId, '0000'),
    9,
    0
FROM CorvelProvider 
WHERE IsNew = 1;

ALTER TABLE PROVIDER ENABLE TRIGGER ALL;

IF @@ERROR = 0  
    COMMIT;  
ELSE  
    ROLLBACK;


-- debug
select * from PROVIDER;
