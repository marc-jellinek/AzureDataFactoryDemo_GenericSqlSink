-- don't forget to connect to the sink server

-- if utils schema doesn't exist, create it
IF (SELECT COUNT(*)
FROM sys.schemas sch
WHERE sch.name = 'utils') = 0 
    BEGIN
    EXEC ('CREATE SCHEMA utils')
END
GO

-- Clean up string values, removing tabs, CR, LF, double-quote, single-quote etc
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
            @InputString,  
            ' ', ''), 
            '\"', '"'),     -- convert escaped double-quote to un-escaped double-quote
            CHAR(9), ''),   -- remove tabs
            CHAR(10), ''),  -- remove linefeed character
            CHAR(13), '');  -- remove carriage return character

    RETURN @OutputString
END
GO

-- create function to generate json for existing tables
CREATE OR ALTER FUNCTION [utils].[GenerateJSONFromTables] 
    (
        @azureSqlDatabaseTableSchemaName varchar(8000), 
        @azureSqlDatabaseTableTableName varchar(8000)
    )
RETURNS varchar(8000)
    BEGIN
    DECLARE @JSONStructure varchar(8000);

    SET @JSONStructure = (
            SELECT col.name as [name],
        CASE WHEN typ.name = '' THEN '' 
                            ELSE 'String'
                        END     as [type]
    FROM sys.schemas sch
        INNER JOIN sys.tables tbl ON sch.schema_id = tbl.schema_id
        INNER JOIN sys.columns col ON tbl.object_id = col.object_id
        INNER JOIN sys.types typ ON col.user_type_id = typ.user_type_id
    WHERE       sch.name = @azureSqlDatabaseTableSchemaName AND
        tbl.name = @azureSqlDatabaseTableTableName AND
        NOT col.name IN     (   '__RowID', 
                                '__sourceConnectionStringSecretName', 
                                '__sinkConnectionStringSecretName', 
                                '__sourceObjectName', 
                                '__sinkObjectName', 
                                '__dataFactoryName', 
                                '__dataFactoryPipelineName',
                                '__dataFactoryPipelineRunId',
                                '__insertDateTimeUTC'
                            )
    ORDER BY    col.column_id
    FOR JSON AUTO 
        );

    SET @JSONStructure = [utils].[CleanseString](@JSONStructure);

    RETURN @JSONStructure;
END
GO

CREATE OR ALTER PROCEDURE [utils].[sp_GetTableBasedOnSuppliedStructure]
    @SuppliedStructure varchar(8000),
    @azureSqlDatabaseTableSchemaName varchar(8000) OUTPUT,
    @azureSqlDatabaseTableTableName varchar(8000) OUTPUT,
    @MultipleMatches bit OUTPUT
AS
BEGIN
    DECLARE @CountMatches bigint = NULL;

    DROP TABLE IF EXISTS #JsonTableStructure;

    SELECT sch.name as schema_name,
        tbl.name as table_name,
        [utils].[GenerateJSONFromTables](sch.name, tbl.name) as JsonStructure
    INTO        #JsonTableStructure
    FROM sys.schemas sch
        INNER JOIN sys.tables tbl ON sch.schema_id = tbl.schema_id;

    SET         @SuppliedStructure = [utils].[CleanseString](@SuppliedStructure);

    SELECT      @CountMatches = ISNULL(COUNT_BIG(*), 0)
    FROM        #JsonTableStructure j
    WHERE       j.JsonStructure = @SuppliedStructure;

    IF @CountMatches = 0 
    BEGIN
        SET @MultipleMatches = 0;
        SET @azureSqlDatabaseTableSchemaName = NULL;
        SET @azureSqlDatabaseTableTableName = NULL;
    END

    IF @CountMatches = 1
    BEGIN
        SET @MultipleMatches = 0;

        SELECT @azureSqlDatabaseTableSchemaName = j.schema_name,
            @azureSqlDatabaseTableTableName = j.table_name
        FROM #JsonTableStructure j
        WHERE       j.JsonStructure = @SuppliedStructure;
    END

    IF @CountMatches > 1
    BEGIN
        SET @MultipleMatches = 1;
        SET @azureSqlDatabaseTableSchemaName = NULL;
        SET @azureSqlDatabaseTableTableName = NULL;
    END
END 
GO

CREATE OR ALTER PROCEDURE [utils].[sp_CreateTableFromJSON]
    @azureBlobSingleCSVContainerName varchar(1000),
    @azureBlobSingleCSVFolderPath varchar(1000), 
    @azureBlobSingleCSVFileName varchar(1000),
    @SuppliedStructure as varchar(8000),
    @azureSqlDatabaseTableSchemaName varchar(8000) OUTPUT,
    @azureSqlDatabaseTableTableName varchar(8000) OUTPUT
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

    SET @azureSqlDatabaseTableSchemaName = 'utils';
    SET @azureSqlDatabaseTableTableName = CONVERT(varchar(8000), @azureBlobSingleCSVContainerName) + '/' + CONVERT(varchar(8000), @azureBlobSingleCSVFolderPath) + '/' + CONVERT(varchar(8000), @azureBlobSingleCSVFileName) + '/' + CONVERT(varchar(8000), GETUTCDATE(), 126);

    SET @Create = 'CREATE TABLE ' + QUOTENAME(@azureSqlDatabaseTableSchemaName) + '.' + QUOTENAME(@azureSqlDatabaseTableTableName);

    SELECT @Columns  = '[__RowID] bigint IDENTITY PRIMARY KEY CLUSTERED, ';

    SELECT @Columns += columndef.name
    FROM (   SELECT QUOTENAME(columnspec.Name) + ' varchar(max), ' as name
        FROM OPENJSON(@SuppliedStructure)
                                WITH (
                                    [Name] varchar(8000) '$.name', 
                                    [Type] varchar(8000) '$.type'
                                ) columnspec
                ) columndef;

    SELECT @Columns += '[__sourceConnectionStringSecretName] varchar(1000), ';
    SELECT @Columns += '[__sinkConnectionStringSecretName] varchar(1000), ';
    SELECT @Columns += '[__sourceObjectName] varchar(1000), ';
    SELECT @Columns += '[__sinkObjectName] varchar(1000), ';
    SELECT @Columns += '[__dataFactoryName] varchar(1000), ';
    SELECT @Columns += '[__dataFactoryPipelineName] varchar(1000), ';
    SELECT @Columns += '[__dataFactoryPipelineRunId] varchar(1000), ';
    SELECT @Columns += '[__insertDateTimeUTC] datetime2(7) DEFAULT GETUTCDATE() ';

    SET @sql = @Create + '(' + @Columns + ')';

    EXEC(@sql);
END 
GO

CREATE OR ALTER PROCEDURE [utils].[sp_FindOrCreateSinkTable]
    @azureBlobSingleCSVContainerName varchar(1000),
    @azureBlobSingleCSVFolderPath varchar(1000), 
    @azureBlobSingleCSVFileName varchar(1000),
    @SuppliedStructure varchar(8000),
    @azureSqlDatabaseTableSchemaName varchar(8000) OUTPUT,
    @azureSqlDatabaseTableTableName varchar(8000) OUTPUT,
    @MultipleMatches bit OUTPUT
AS
BEGIN

    EXEC [utils].[sp_GetTableBasedOnSuppliedStructure] 
        @SuppliedStructure = @SuppliedStructure, 
        @azureSqlDatabaseTableSchemaName = @azureSqlDatabaseTableSchemaName OUTPUT, 
        @azureSqlDatabaseTableTableName = @azureSqlDatabaseTableTableName OUTPUT, 
        @MultipleMatches = @MultipleMatches OUTPUT

    IF (@azureSqlDatabaseTableSchemaName IS NULL AND @azureSqlDatabaseTableTableName IS NULL) OR -- No matching table, create new
        (@MultipleMatches = 1)                          -- many matching tables, I don't know which to load, instead create another new table
    BEGIN
        EXEC utils.sp_CreateTableFromJSON 
            @azureBlobSingleCSVContainerName = @azureBlobSingleCSVContainerName, 
            @azureBlobSingleCSVFolderPath = @azureBlobSingleCSVFolderPath, 
            @azureBlobSingleCSVFileName = @azureBlobSingleCSVFileName, 
            @SuppliedStructure = @SuppliedStructure,
            @azureSqlDatabaseTableSchemaName = @azureSqlDatabaseTableSchemaName OUTPUT, 
            @azureSqlDatabaseTableTableName = @azureSqlDatabaseTableTableName OUTPUT
    END 
    
    SELECT  @azureSqlDatabaseTableSchemaName as azureSqlDatabaseTableSchemaName,
            @azureSqlDatabaseTableTableName as azureSqlDatabaseTableTableName,
            @MultipleMatches as MultipleMatches
END 
GO

CREATE OR ALTER PROCEDURE [utils].[sp_RenameUtilsTable]
    @OriginalSchemaName varchar(8000),  
    @OriginalTableName varchar(8000), 
    @NewSchemaName varchar(8000), 
    @NewTableName varchar(8000)
AS 
BEGIN 
    DECLARE @OriginalObjectName varchar(8000) = QUOTENAME(@OriginalSchemaName) + '.' + QUOTENAME(@OriginalTableName)
    DECLARE @NewObjectName varchar(8000) = QUOTENAME(@NewSchemaName) + '.' + QUOTENAME(@NewTableName)
    DECLARE @InterimObjectName varchar(8000) = QUOTENAME(@OriginalSchemaName) + '.' + QUOTENAME(@NewTableName)

	DECLARE @sql varchar(8000)

    -- TODO:  Find a better way to do this
    -- Technically suseptible to SQL injection.  
    -- Would have to be run as db_owner or other highly-priv principal, 
    -- they already have rights to do damage.
    -- Best to clean this up ASAP for sake of good form
    
    EXEC sp_rename @OriginalObjectName, @NewTableName

    SET @sql = 'ALTER SCHEMA ' +  @NewSchemaName + ' TRANSFER ' + @InterimObjectName + ';'
	EXEC (@sql)

    SET @sql = 'GRANT SELECT ON ' + @NewObjectName + 'TO DataLoaders;'
	EXEC (@sql) 

    SET @sql = 'GRANT INSERT ON ' + @NewObjectName + 'TO DataLoaders;'
	EXEC (@sql) 

    SET @sql = 'GRANT ALTER ON ' + @NewObjectName + 'TO DataLoaders;' -- required for TRUNCATE TABLE
	EXEC (@sql) 

END 
GO

CREATE ROLE DataLoaders;
GO

GRANT ALTER ON SCHEMA::[utils] TO DataLoaders;
GO

GRANT CREATE TABLE TO DataLoaders;
GO

GRANT SELECT ON SCHEMA::[utils] TO DataLoaders;
GO

GRANT INSERT ON SCHEMA::[utils] TO Dataloaders;
GO

GRANT EXECUTE ON SCHEMA::[utils] TO DataLoaders;
GO
