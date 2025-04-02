USE [QA_INTM_Temp4Dts]
GO

-- Drop views in dependency order
-- Remove existing views to ensure clean import process
IF OBJECT_ID('Medata_EXTRACT') IS NOT NULL DROP VIEW Medata_EXTRACT;
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

IF OBJECT_ID('TempBillLineData', 'U') IS NOT NULL
BEGIN
DROP TABLE TempBillLineData;
END;

-- TempBillLineData table structure:
-- ID: Unique identifier
-- Value: Raw bill line data
CREATE TABLE TempBillLineData (
    ID INT IDENTITY PRIMARY KEY,              -- Unique identifier
    Value NVARCHAR(MAX)                      -- Raw bill line data
);
GO

--==============================================================================
-- Import Column Definitions
--==============================================================================

-- Map staged data to final table with proper field mappings
DELETE FROM TempBillColumns where Source = 'LAWA';
INSERT INTO TempBillColumns (FieldName, Length, DataType, UsageDescription, StartOffset, EndOffset, Source)
SELECT FieldName, Length, Attribute, Usage, StartByte, EndByte, 'LAWA'
FROM bill_columns;

select * from TempBillColumns;
--==============================================================================
-- Import Bill Data
--==============================================================================

-- Transfer valid data to final table

INSERT INTO TempBillLineData (Value)
SELECT [Column 0]
FROM [BIG_EXTRACT_20170401-20250228_byclmlst]
WHERE LEN(RTRIM([Column 0])) > 0;              -- Skip empty lines

GO

select top 1 * from TempBillLineData;

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

-- Medata_EXTRACT: Create final view with proper column names
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
CREATE VIEW Medata_EXTRACT WITH SCHEMABINDING AS
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
WHERE object_id = OBJECT_ID('Medata_EXTRACT')
ORDER BY column_id;

-- Preview parsed data
SELECT TOP 5 ReviewReductionCode01 FROM Medata_EXTRACT;

select count(*) from Medata_EXTRACT;