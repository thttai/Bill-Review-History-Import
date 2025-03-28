USE [MyLocalDB]
GO

-- Configuration
-- Define source system identifier and file paths for column definitions and bill data
DECLARE @Source VARCHAR(10) = 'LAWA';             -- Source system identifier
DECLARE @BillColumnFile VARCHAR(255) = 'C:\Users\Admin\source\repos\Bill Review History Import\bill_columns.csv';
DECLARE @BillDataFile VARCHAR(255) = 'C:\Users\Admin\source\repos\SQLData\BIG_EXTRACT_20170401-20250228_byclmlst.TXT';

-- Drop views in dependency order
-- Remove existing views to ensure clean import process
IF OBJECT_ID('Medata_LAWA_BIG_EXTRACT_20170401_20250228t') IS NOT NULL DROP VIEW Medata_LAWA_BIG_EXTRACT_20170401_20250228;
IF OBJECT_ID('vw_BillLinesParsed') IS NOT NULL DROP VIEW vw_BillLinesParsed;

-- Create base tables
-- Define structure for storing column definitions and bill line data
IF OBJECT_ID('TempBillColumns', 'U') IS NULL
BEGIN
    -- TempBillColumns table structure:
    -- ID: Unique identifier
    -- FieldName: Field name from column definitions
    -- StartOffset: Start position of field in fixed-width data (1-based)
    -- EndOffset: End position of field in fixed-width data
    -- Length: Field length
    -- DataType: Data type of field (e.g. DT=Date, AN=AlphaNumeric)
    -- UsageDescription: Field description
    -- Source: Source system identifier
    CREATE TABLE TempBillColumns (
        ID INT IDENTITY PRIMARY KEY,              -- Unique identifier
        FieldName NVARCHAR(100),                 -- Field name
        StartOffset INT,                         -- Start position (1-based)
        EndOffset INT,                           -- End position
        Length INT,                              -- Field length
        DataType NVARCHAR(10),                   -- e.g. DT=Date, AN=AlphaNumeric
        UsageDescription NVARCHAR(512),          -- Field description
        Source NVARCHAR(100)                     -- Source system
    );
END;

IF OBJECT_ID('TempBillLineData', 'U') IS NULL
BEGIN
    -- TempBillLineData table structure:
    -- ID: Unique identifier
    -- Value: Raw bill line data
    CREATE TABLE TempBillLineData (
        ID INT IDENTITY PRIMARY KEY,              -- Unique identifier
        Value NVARCHAR(MAX)                      -- Raw bill line data
    );
END;

--==============================================================================
-- Import Column Definitions
--==============================================================================
-- Create staging table for CSV import
CREATE TABLE #StagingBillColumns (
    FieldName NVARCHAR(100),                     -- Field name from CSV
    Length INT,                                  -- Field length
    Attribute NVARCHAR(10),                      -- Data type (e.g. DT, AN)
    Usage NVARCHAR(512),                         -- Field description
    StartByte INT,                              -- Start position in line
    EndByte INT                                 -- End position in line
);

 -- Import CSV data using dynamic SQL for variable file path
DECLARE @BulkSQL1 NVARCHAR(MAX);
SET @BulkSQL1 = 
'BULK INSERT #StagingBillColumns
FROM ''' + @BillColumnFile + '''
WITH (
     FORMAT = ''CSV'',
     FIRSTROW = 2,                               -- Skip header row
     FIELDTERMINATOR = '','',
     ROWTERMINATOR = ''\n'',
     KEEPNULLS
 );'

EXEC sp_executesql @BulkSQL1;

-- Map staged data to final table with proper field mappings
DELETE FROM TempBillColumns;
INSERT INTO TempBillColumns (FieldName, Length, DataType, UsageDescription, StartOffset, EndOffset, Source)
SELECT FieldName, Length, Attribute, Usage, StartByte, EndByte, @Source
FROM #StagingBillColumns;

DROP TABLE #StagingBillColumns;

--==============================================================================
-- Import Bill Data
--==============================================================================
-- Create staging table for raw fixed-width data
CREATE TABLE #StagingBillLineData (
    RawLineData NVARCHAR(MAX)                    -- Raw fixed-width line
);

-- Import bill data using dynamic SQL for variable file path
DECLARE @BulkSQL NVARCHAR(MAX);
SET @BulkSQL = 
'BULK INSERT #StagingBillLineData
FROM ''' + @BillDataFile + '''
WITH (
    ROWTERMINATOR = ''0x0A'',                    -- Line feed character
    FIELDTERMINATOR = '''',                      -- No separator for fixed-width
    CODEPAGE = ''65001'',                        -- UTF-8 encoding
    KEEPNULLS,
    TABLOCK                                      -- Table lock for performance
);'

EXEC sp_executesql @BulkSQL;

-- Transfer valid data to final table
TRUNCATE TABLE TempBillLineData;
INSERT INTO TempBillLineData (Value)
SELECT RawLineData
FROM #StagingBillLineData
WHERE LEN(RTRIM(RawLineData)) > 0;              -- Skip empty lines

DROP TABLE #StagingBillLineData;
GO

--==============================================================================
-- Create Views
--==============================================================================
-- vw_BillLinesParsed: Parse fixed-width lines into individual fields
CREATE VIEW vw_BillLinesParsed WITH SCHEMABINDING AS
WITH ParsedFields AS (
    SELECT 
        l.ID as LineID,                          -- Line identifier
        TRIM(SUBSTRING(l.Value,                  -- Extract field using positions
            c.StartOffset, c.Length)) as FieldValue,
        c.FieldName,                             -- Field name from definition
        c.DataType                               -- For data type validation
    FROM dbo.TempBillLineData l
    CROSS JOIN dbo.TempBillColumns c
    WHERE c.Source = 'LAWA'                      -- Filter by source system
)
SELECT 
    LineID,
    FieldName,
    TRIM(FieldValue) as ParsedValue,             -- Clean field value
    DataType
FROM ParsedFields;
GO

-- Medata_LAWA_BIG_EXTRACT_20170401_20250228: Create final view with proper column names
DECLARE @sql NVARCHAR(MAX);
DECLARE @columns NVARCHAR(MAX);

-- Handle duplicate field names by adding numeric suffix
WITH NumberedFields AS (
    SELECT 
        FieldName,
        ROW_NUMBER() OVER (                      -- Add counter for duplicates
            PARTITION BY REPLACE(REPLACE(REPLACE(FieldName, ' ', '_'), '-', '_'), '/', '_') 
            ORDER BY StartOffset
        ) as FieldCount
    FROM TempBillColumns
    WHERE Source = 'LAWA'                        -- Filter by source system
)
SELECT @columns = STRING_AGG(CAST(
    'MAX(CASE WHEN FieldName = ''' + FieldName + ''' THEN ParsedValue END) as ' + 
    REPLACE(REPLACE(REPLACE(FieldName, ' ', ''), '-', ''), '/', '') + 
    CASE 
        WHEN FieldCount > 1 THEN CAST(FieldCount as VARCHAR(2))  -- Add suffix for duplicates
        ELSE ''
    END
    as varchar(200)),
    ', ')
FROM NumberedFields;

-- Create final view with dynamic columns
SET @sql = N'
CREATE VIEW Medata_LAWA_BIG_EXTRACT_20170401_20250228 WITH SCHEMABINDING AS
SELECT 
    LineID,                                      -- Preserve line order
    ' + @columns + '                             -- Dynamic field columns
FROM dbo.vw_BillLinesParsed
GROUP BY LineID;
';

EXEC sp_executesql @sql;
GO

--==============================================================================
-- Verification
--==============================================================================
-- Display column structure
SELECT name, column_id 
FROM sys.columns 
WHERE object_id = OBJECT_ID('Medata_LAWA_BIG_EXTRACT_20170401_20250228')
ORDER BY column_id;

-- Preview parsed data
SELECT TOP 5 * FROM Medata_LAWA_BIG_EXTRACT_20170401_20250228 where CustomerLineNumber = '2702735983';

-- Debug query 1: Show all parsed fields
SELECT 
    LineID,
    FieldName,
    DataType,
    ParsedValue,
    LEN(ParsedValue) as ValueLength
FROM vw_BillLinesParsed
ORDER BY LineID, FieldName;

-- Debug query 2: Show specific fields
SELECT 
    LineID,
    FieldName,
    ParsedValue,
    DataType
FROM vw_BillLinesParsed
WHERE FieldName IN (
    'Bill ID Date',
    'Procedure Code or Service Code',
    'Charges',
    'Claimant Last Name',
    'Provider ID'
)
ORDER BY LineID, FieldName;

-- Debug query 3: Check for NULL or empty values
SELECT 
    FieldName,
    COUNT(*) as TotalRows,
    SUM(CASE WHEN ParsedValue IS NULL THEN 1 ELSE 0 END) as NullCount,
    SUM(CASE WHEN ParsedValue = '' THEN 1 ELSE 0 END) as EmptyCount
FROM vw_BillLinesParsed
GROUP BY FieldName
HAVING SUM(CASE WHEN ParsedValue IS NULL THEN 1 ELSE 0 END) > 0
    OR SUM(CASE WHEN ParsedValue = '' THEN 1 ELSE 0 END) > 0
ORDER BY FieldName;


select count(*) from Medata_LAWA_BIG_EXTRACT_20170401_20250228;