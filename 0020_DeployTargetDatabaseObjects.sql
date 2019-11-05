-- don't forget to connect to the target server

-- if utils schema doesn't exist, create it
IF (SELECT COUNT(*)
FROM sys.schemas sch
WHERE sch.name = 'utils') = 0 
    BEGIN
    EXEC ('CREATE SCHEMA utils')
END
GO

-- if audit schema doesn't exist, create it
IF (SELECT COUNT(*)
FROM sys.schemas sch
WHERE sch.name = 'audit') = 0 
    BEGIN
    EXEC ('CREATE SCHEMA audit')
END
GO

DROP TABLE IF EXISTS audit.OperationsEventLog;
GO

CREATE TABLE audit.OperationsEventLog(
    OpsSK bigint IDENTITY,
    EventDateTime datetime DEFAULT GETUTCDATE(),
    EventState varchar(8000),
    SourceType varchar(8000),
    -- stored procedure, data factory pipeline, etc
    SourceName varchar(8000),
    StatusMessage varchar(8000) NOT NULL
);
GO

DROP PROCEDURE IF EXISTS audit.InsertOperationsEventLog;
GO

CREATE PROCEDURE audit.InsertOperationsEventLog
    @EventState varchar(8000),
    @SourceType varchar(8000),
    -- stored procedure, data factory pipeline, etc
    @SourceName varchar(8000),
    @StatusMessage varchar(8000)
AS
BEGIN
    BEGIN TRY
        INSERT INTO audit.OperationsEventLog
        ([EventState], [SourceType], [SourceName], [StatusMessage])
    VALUES
        (@EventState, @SourceType, @SourceName, @StatusMessage)
    END TRY
    BEGIN CATCH
        SELECT ERROR_NUMBER() as ErrorNumber,
        ERROR_MESSAGE() as ErrorMessage;

        THROW;
    END CATCH
END
GO

/*
DROP TABLE IF EXISTS dbo.TestTable; 
GO

CREATE TABLE dbo.TestTable
(
    id int IDENTITY
) -- First test case should match dbo.TestTable
GO

DROP TABLE IF EXISTS dbo.TestTable2;

CREATE TABLE dbo.TestTable2
(
    id int IDENTITY,
    name varchar(100)
); -- Duplicate table, data with same schema should be routed to a new table
GO

DROP TABLE IF EXISTS dbo.TestTable3;

CREATE TABLE dbo.TestTable3
(
    id int IDENTITY,
    name varchar(100)
); -- Duplicate table, data with same schema should be routed to a new table
GO
*/

-- Clean up string values, removing tabs, CR, LF, etc
CREATE OR ALTER FUNCTION [utils].[CleanseString]
    (
        @InputString varchar(8000)
    )
RETURNS varchar(8000)
    BEGIN
    DECLARE @OutputString varchar(8000)

    SET @OutputString = 
                REPLACE(
                REPLACE(
                REPLACE(
                REPLACE(
                REPLACE(
                REPLACE(
                REPLACE(
                REPLACE(
                    @InputString,  
                    ' ', ''), 
                    '\', ''), 
                    '/', ''), 
                    '-', ''), 
                    '\"', ''), 
                    CHAR(9), ''), 
                    CHAR(10), ''), 
                    CHAR(13), '');

    RETURN @OutputString
END
GO

-- create function to generate json for existing tables
CREATE OR ALTER FUNCTION [utils].[GenerateJSONFromViews] 
    (
        @SchemaName sysname, 
        @ViewName sysname
    )
RETURNS varchar(8000)
    BEGIN
    DECLARE @JSONStructure varchar(8000)

    SET @JSONStructure = (
            SELECT col.name as [name],
        CASE WHEN typ.name = '' THEN '' 
                            ELSE 'String'
                        END     as [type]
    FROM sys.schemas sch
        INNER JOIN sys.views vws ON sch.schema_id = vws.schema_id
        INNER JOIN sys.columns col ON vws.object_id = col.object_id
        INNER JOIN sys.types typ ON col.user_type_id = typ.user_type_id
    WHERE       sch.name = @SchemaName AND
        vws.name = @ViewName AND
        NOT col.name = '__RowID' AND
        NOT col.name = '__StorageAccountName' AND 
        NOT col.name = '__FileName' AND
        NOT col.name = '__DataFactoryName' AND
        NOT col.name = '__DataFactoryPipelineName' AND
        NOT col.name = '__DataFactoryPipelineRunId'
    ORDER BY    col.column_id
    FOR JSON AUTO 
        )

    SET @JSONStructure = [utils].[CleanseString](@JSONStructure)

    RETURN @JSONStructure
END
GO

CREATE OR ALTER PROCEDURE [utils].[sp_GetViewBasedOnSuppliedStructure]
    @SuppliedStructure varchar(8000),
    @SchemaName sysname OUTPUT,
    @ViewName sysname OUTPUT,
    @MultipleMatches bit OUTPUT
AS
BEGIN
    DECLARE @CountMatches bigint = NULL;

    DROP TABLE IF EXISTS #JsonViewStructure;

    SELECT sch.name as schema_name,
        vws.name as view_name,
        [utils].[GenerateJSONFromViews](sch.name, vws.name) as JsonStructure
    INTO        #JsonViewStructure
    FROM sys.schemas sch
        INNER JOIN sys.views vws ON sch.schema_id = vws.schema_id;

    SET         @SuppliedStructure = [utils].[CleanseString](@SuppliedStructure);

    SELECT @CountMatches = ISNULL(COUNT_BIG(*), 0)
    FROM #JsonViewStructure j
    WHERE       j.JsonStructure = @SuppliedStructure;

    IF @CountMatches = 0 
    BEGIN
        SET @MultipleMatches = 0;
        SET @SchemaName = NULL;
        SET @ViewName = NULL;
    END

    IF @CountMatches = 1
    BEGIN
        SET @MultipleMatches = 0;

        SELECT @SchemaName = j.schema_name,
            @ViewName = j.view_name
        FROM #JsonViewStructure j
        WHERE       j.JsonStructure = @SuppliedStructure;
    END

    IF @CountMatches > 1
    BEGIN
        SET @MultipleMatches = 1;
        SET @SchemaName = NULL;
        SET @ViewName = NULL;
    END
END 
GO

CREATE OR ALTER PROCEDURE [utils].[sp_CreateTableAndViewFromJSON]
    @FileName varchar(1000), 
    @SuppliedStructure as varchar(8000),
    @SchemaName sysname OUTPUT,
    @TableName sysname OUTPUT, 
    @ViewName sysname OUTPUT 
AS
BEGIN
    -- expects array of objects with name and type properties generated from Azure Data Factory Get Metadata activity
    -- example: '
    /*
    [ 
        {
            "name": "test1",
            "type": "String"
        }, 
        {
            "name": "test2",
            "type": "String"
        }
    ]
    */
    DECLARE @sql varchar(8000);
    DECLARE @Create varchar(8000);
    DECLARE @Columns varchar(8000) = N'';

    SET @SuppliedStructure = [utils].[CleanseString](@SuppliedStructure);

    SET @SchemaName = 'utils';
    SET @TableName = CONVERT(sysname, @FileName) + N'-' + CONVERT(sysname, GETUTCDATE(), 126);

    SET @Create = 'CREATE TABLE ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName);    
    
    SELECT @Columns  = '[__RowID] bigint IDENTITY PRIMARY KEY CLUSTERED, ';

    SELECT @Columns += columndef.name
    FROM (   SELECT QUOTENAME(columnspec.Name) + ' varchar(max), ' as name
        FROM OPENJSON(@SuppliedStructure)
                                WITH (
                                    [Name] sysname '$.name', 
                                    [Type] sysname '$.type'
                                ) columnspec
                ) columndef;

    SELECT @Columns += '[__StorageAccountName] varchar(1000), ';
    SELECT @Columns += '[__FileName] varchar(1000), ';
    SELECT @Columns += '[__DataFactoryName] varchar(1000), ';
    SELECT @Columns += '[__DataFactoryPipelineName] varchar(1000), ';
    SELECT @Columns += '[__DataFactoryPipelineRunId] varchar(1000), ';
    SELECT @Columns += '[__InsertDateTimeUTC] datetime2(7) DEFAULT GETDATE() ';

    SET @sql = @Create + '(' + @Columns + ')';
    
    EXEC(@sql);

    SET @ViewName = 'vw_' + @TableName;

    -- create a view based on this table that excludes [__RowID] so data factory can insert into the view without mapping columns
    SET @Create = 'CREATE VIEW ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@ViewName);
    SET @Create += ' AS SELECT ';

    SELECT @Columns = '';

    SELECT @Columns += columndef.name
    FROM (   SELECT QUOTENAME(columnspec.Name) + ', ' as name
        FROM OPENJSON(@SuppliedStructure)
                                WITH (
                                    [Name] sysname '$.name'
                                ) columnspec
                ) columndef;

    SELECT @Columns += '[__StorageAccountName], ';
    SELECT @Columns += '[__FileName], ';
    SELECT @Columns += '[__DataFactoryName], ';
    SELECT @Columns += '[__DataFactoryPipelineName], ';
    SELECT @Columns += '[__DataFactoryPipelineRunId], ';
    SELECT @Columns += '[__InsertDateTimeUTC]';

    SET @Columns += ' FROM ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName);

    SET @sql = @Create + @Columns;

    EXEC (@sql);
END 
GO

CREATE OR ALTER PROCEDURE [utils].[sp_FindOrCreateTargetView]
    @FileName varchar(1000), 
    @SuppliedStructure varchar(8000),
    @SchemaName sysname OUTPUT,
    @ViewName sysname OUTPUT,
    @MultipleMatches bit OUTPUT
AS
BEGIN
    DECLARE @TableName sysname;

    EXEC [utils].[sp_GetViewBasedOnSuppliedStructure] 
        @SuppliedStructure = @SuppliedStructure, 
        @SchemaName = @SchemaName OUTPUT, 
        @ViewName = @ViewName OUTPUT, 
        @MultipleMatches = @MultipleMatches OUTPUT

    IF (@SchemaName IS NULL AND @ViewName IS NULL) OR -- No matching table, create new
       (@MultipleMatches = 1)                          -- many matching tables, create a new one
    BEGIN
        EXEC utils.sp_CreateTableAndViewFromJSON 
            @FileName = @FileName, 
            @SuppliedStructure = @SuppliedStructure,
            @SchemaName = @SchemaName OUTPUT, 
            @TableName = @TableName OUTPUT, 
            @ViewName = @ViewName OUTPUT

        SELECT  @SchemaName as SchemaName, 
                @ViewName as ViewName, 
                @MultipleMatches as MultipleMatches
    END
    ELSE
    BEGIN
        SELECT  @SchemaName as SchemaName, 
                @ViewName as ViewName, 
                @MultipleMatches as MultipleMatches
    END


END 
GO
  --More Testing
/*
DECLARE @SuppliedStructure varchar(8000) = '[{"name":"id", "type":"string"}]';

DECLARE @SchemaName sysname;
DECLARE @ViewName sysname;
DECLARE @MultipleMatches bit = 0;
DECLARE @FileName varchar(1000) = '0030_SourceData1.csv'

EXEC [utils].[sp_FindOrCreateTargetView] 
    @FileName = @FileName, 
    @SuppliedStructure = @SuppliedStructure, 
    @SchemaName = @SchemaName OUTPUT, 
    @ViewName = @ViewName OUTPUT, 
    @MultipleMatches = @MultipleMatches OUTPUT

SELECT  @SchemaName, @ViewName, @MultipleMatches
*/

-- Testing
/*

--DECLARE @SuppliedStructure varchar(8000) = '[{"name": "id", "type": "String"}]'
DECLARE @SuppliedStructure varchar(8000) = '[{"name": "id", "type": "String"}, {"name": "name", "type": "String"}]'

-- Call from Data Factory Lookup.
-- Output Parameter @SchemaName passed back to the activity 
--    - The schema within which the table lives
-- Output Parameter @TableName passed back to the activity 
--    - The table which matched based on structure, or 
--    - when unmatched, the new table that was created to hold incoming data
--    - multiple matches returns the table name of the new table that was created
-- Output Parameter @MultipleMatches is there as a flag to let someone know that a new table was created and they have multiple matches based on structure
DECLARE @SchemaName sysname;
DECLARE @TableName sysname;
DECLARE @MultipleMatches bit = 0;
DECLARE @FileName varchar(1000);

EXEC [utils].[sp_FindOrCreateTargetTable] 
    @FileName = @FileName, 
    @SuppliedStructure = @SuppliedStructure, 
    @SchemaName = @SchemaName OUTPUT, 
    @TableName = @TableName OUTPUT, 
    @MultipleMatches = @MultipleMatches OUTPUT 

IF @MultipleMatches = 1 
    PRINT 'Multiple Matches - inserting into new table ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName)
ELSE
    PRINT 'Inserting into table ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName)

SELECT @SchemaName as SchemaName, 
    @TableName as TableName, 
    @MultipleMatches as MultipleMatches
*/