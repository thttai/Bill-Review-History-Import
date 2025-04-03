USE [QA_INTM_Temp4Dts]
GO

-- NOTE: LOAD RAW FILE DATA TO TABLE [TempMedataData] using import wizard


-- FOR DEBUG ONLY

-- vwTempMedataParser - parse all columns from data line w/o trimming
-- vwTempMedataBillHeader - Select distinct only needed bill headers cols from the vwTempMedataParser with space trim
-- vwTempMedataBillDetail - Select only needed bill detailcols from the vwTempMedataParser with space trim

-- Drop views in dependency order
-- Remove existing views to ensure clean import process
IF OBJECT_ID('vwTempMedataParser') IS NOT NULL DROP VIEW vwTempMedataParser;
IF OBJECT_ID('vw_BillLinesParsed') IS NOT NULL DROP VIEW vw_BillLinesParsed;
GO

-- Create base tables
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

--==============================================================================
-- Import Bill Data
--==============================================================================

-- Transfer valid data to final table

INSERT INTO TempBillLineData (Value)
SELECT [Column 0]
FROM [TempMedataData]
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
            c.StartByte, c.Length)) as FieldValue,
        c.FieldName,                             -- Field name from definition
        c.Attribute                               -- For data type validation
    FROM dbo.TempBillLineData l
    CROSS JOIN dbo.bill_columns c
)
SELECT 
    LineID,
    FieldName,
    TRIM(FieldValue) as ParsedValue,             -- Clean field value
    DataType
FROM ParsedFields;
GO

-- vwTempMedataParser: Create final view with proper column names
DECLARE @sql NVARCHAR(MAX);
DECLARE @columns NVARCHAR(MAX);

-- Handle duplicate field names by adding numeric suffix
WITH NumberedFields AS (
    SELECT 
        FieldName,
        ROW_NUMBER() OVER (                      -- Add counter for duplicates
            PARTITION BY REPLACE(REPLACE(REPLACE(FieldName, ' ', '_'), '-', '_'), '/', '_') 
            ORDER BY StartByte
        ) as FieldCount
    FROM dbo.bill_columns
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
GO

-- Create final view with dynamic columns
SET @sql = N'
CREATE VIEW vwTempMedataParser WITH SCHEMABINDING AS
SELECT 
    LineID,                                      -- Preserve line order
    ' + @columns + '                             -- Dynamic field columns
FROM dbo.vw_BillLinesParsed
GROUP BY LineID;
';

EXEC sp_executesql @sql;
GO

DROP VIEW vw_BillLinesParsed;
GO

--==============================================================================
-- Verification
--==============================================================================
-- Display column structure
SELECT name, column_id 
FROM sys.columns 
WHERE object_id = OBJECT_ID('vwTempMedataParser')
ORDER BY column_id;

-- Preview parsed data

select count(*) from vwTempMedataParser;

select count(*), BillID from vwTempMedataParser group by BillID;