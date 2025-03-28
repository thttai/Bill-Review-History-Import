EXEC sp_addlinkedserver 
    @server = 'DataQA',  -- Alias for the linked server
    @srvproduct = '', 
    @provider = 'SQLNCLI', 
    @datasrc = 'dataqa.managewaresolutions.com';

-- If authentication is required:
EXEC sp_addlinkedsrvlogin 
    @rmtsrvname = 'DataQA',
    @useself = 'false',
    @rmtuser = 'sa',
    @rmtpassword = 'Not4u2c';

SELECT TOP 100 id, Edi_Source_Code, claimno  
FROM [DataQA].[QA_INTM_ReviewWare].[dbo].[claim];

select COUNT(*) from [DataQA].[QA_INTM_ReviewWare].[dbo].[claim];
-- import claim from QA DB to local DB
SELECT top 20000 *
INTO [claim]
FROM [DataQA].[QA_INTM_ReviewWare].[dbo].[claim];
-- debug
select * from [claim];

-- create function on db
--create Function [dbo].[fnGet2csProviderTaxIdExt](@TaxId varchar(9), @EdiSourceCode varchar(10))
--returns varchar(4)
--begin
--	declare @MaxId int, @TaxIdExt varchar(4);

--	select 
--		--* 
--		@MaxId = convert(int,MAX(right(taxid,4)))
--	From
--		[dbo].PROVIDER
--	where left(taxid,9) = @TaxId and ISNULL(Edi_Source_Code,'') = ISNULL(@EdiSourceCode, '');
 
--	If isnull(@MaxId,0) > 0
--	begin
--		set @TaxIdExt =  right('0000' + Convert(varchar,@MaxId + 1), 4);
--	end
--	else
--	begin
--		set @TaxIdExt =  '0001';
--	end
--	return @TaxIdExt;
--end

select  min(id)-1 from [DataQA].[QA_INTM_ReviewWare].[dbo].[claim_bill];


-- import PROVIDER table

--select COUNT(*) from [DataQA].[QA_INTM_ReviewWare].[dbo].[PROVIDER];

--DELETE FROM PROVIDER;

SELECT * FROM PROVIDER; -- Verify deletion (should be empty)

BEGIN TRANSACTION;

SET IDENTITY_INSERT PROVIDER ON;

INSERT INTO PROVIDER (
    ID, 
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
SELECT TOP 20000 
    ID, 
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
FROM [DataQA].[QA_INTM_ReviewWare].[dbo].PROVIDER;

SET IDENTITY_INSERT PROVIDER OFF;

IF @@ERROR = 0  
    COMMIT;  
ELSE  
    ROLLBACK;