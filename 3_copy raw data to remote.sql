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


-- clone a view from the local database to a remote database

-- Create the table on the remote server and copy data
SELECT *
INTO Medata_LAWA_BIG_EXTRACT_20170401_20250228_table
FROM [MyLocalDB].[dbo].[Medata_LAWA_BIG_EXTRACT_20170401_20250228]

INSERT INTO [DataQA].[QA_INTM_Temp4Dts].[dbo].[Medata_LAWA_BIG_EXTRACT_20170401_20250228]
SELECT * FROM [MyLocalDB].[dbo].Medata_LAWA_BIG_EXTRACT_20170401_20250228_table

-- drop temp table
drop table Medata_LAWA_BIG_EXTRACT_20170401_20250228_table;