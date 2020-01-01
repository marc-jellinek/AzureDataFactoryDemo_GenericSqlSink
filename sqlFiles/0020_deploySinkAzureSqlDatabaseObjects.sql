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
            SELECT col.name as [name]
    FROM sys.schemas sch
        INNER JOIN sys.tables tbl ON sch.schema_id = tbl.schema_id
        INNER JOIN sys.columns col ON tbl.object_id = col.object_id
        INNER JOIN sys.types typ ON col.user_type_id = typ.user_type_id
    WHERE       sch.name = @azureSqlDatabaseTableSchemaName AND
        tbl.name = @azureSqlDatabaseTableTableName AND
        NOT col.name IN     (   '__rowId', 
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

    RETURN @JSONStructure;
END
GO

CREATE OR ALTER PROCEDURE [utils].[sp_GetTableBasedOnSuppliedStructure]
    @suppliedStructure varchar(8000),
    @azureSqlDatabaseTableSchemaName varchar(8000) OUTPUT,
    @azureSqlDatabaseTableTableName varchar(8000) OUTPUT,
    @multipleMatches bit OUTPUT
AS
BEGIN
    DECLARE @CountMatches bigint = NULL;
    DECLARE @suppliedColumnList varchar(8000);

    DROP TABLE IF EXISTS #suppliedStructureColumns;
    DROP TABLE IF EXISTS #existingTableStructureColumns;

    SELECT      *
    INTO        #suppliedStructureColumns
    FROM        OPENJSON(@suppliedStructure) WITH ([name] varchar(8000) '$.name')

    DELETE FROM #suppliedStructureColumns  -- these columns are ignored for comparison sake.  If they exist in the source, they will be copied to the target
    WHERE name IN     (   '__rowId', 
                            '__sourceConnectionStringSecretName', 
                            '__sinkConnectionStringSecretName', 
                            '__sourceObjectName', 
                            '__sinkObjectName', 
                            '__dataFactoryName', 
                            '__dataFactoryPipelineName',
                            '__dataFactoryPipelineRunId',
                            '__insertDateTimeUTC'
                        );

    SELECT      @suppliedColumnList =     
                        (   SELECT      STUFF(
                                            (
                                                SELECT      ',' + name 
                                                FROM        #suppliedStructureColumns 
                                                FOR         XML PATH ('')
                                            ), 
                                            1, 
                                            1, 
                                            ''
                                        )
                        );

    SELECT      sch.name as schema_name, 
                tbl.name as table_name, 
                STUFF(
                    (
                        SELECT      ',' + col.name 
                        FROM        sys.columns col
                        WHERE       tbl.object_id  = col.object_id AND
                                    col.name NOT IN     (   '__rowId', 
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
                        FOR         XML PATH ('')
                    ), 
                    1, 
                    1, 
                    ''
                ) as columnlist
    INTO        #existingTableStructureColumns
    FROM        sys.schemas sch
                INNER JOIN sys.tables tbl ON sch.schema_id = tbl.schema_id;

    SELECT      @CountMatches = ISNULL(COUNT_BIG(*), 0)
    FROM        #existingTableStructureColumns exist
    WHERE       exist.columnlist = @suppliedColumnList;

    IF @CountMatches = 0 
        BEGIN
            SET @multipleMatches = 0;
            SET @azureSqlDatabaseTableSchemaName = NULL;
            SET @azureSqlDatabaseTableTableName = NULL;
        END

    IF @CountMatches = 1
        BEGIN
            SET @multipleMatches = 0;

            SELECT      @azureSqlDatabaseTableSchemaName = exist.schema_name, 
                        @azureSqlDatabaseTableTableName = exist.table_name
            FROM        #existingTableStructureColumns exist 
            WHERE       exist.columnlist = @suppliedColumnList
        END

    IF @CountMatches > 1
        BEGIN
            SET @multipleMatches = 1;
            SET @azureSqlDatabaseTableSchemaName = NULL;
            SET @azureSqlDatabaseTableTableName = NULL;
        END        

END 
GO

CREATE OR ALTER PROCEDURE [utils].[sp_CreateTableFromJSON]
    @suppliedStructure as varchar(8000),
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
    DECLARE @DefaultColumnList TABLE (name varchar(8000))

    INSERT INTO @DefaultColumnList (name) VALUES ('__rowId');
    INSERT INTO @DefaultColumnList (name) VALUES ('__sourceConnectionStringSecretName');
    INSERT INTO @DefaultColumnList (name) VALUES ('__sourceConnectionStringSecretName');
    INSERT INTO @DefaultColumnList (name) VALUES ('__sinkConnectionStringSecretName');
    INSERT INTO @DefaultColumnList (name) VALUES ('__sourceObjectName');
    INSERT INTO @DefaultColumnList (name) VALUES ('__sinkObjectName');
    INSERT INTO @DefaultColumnList (name) VALUES ('__dataFactoryName');
    INSERT INTO @DefaultColumnList (name) VALUES ('__dataFactoryPipelineName');
    INSERT INTO @DefaultColumnList (name) VALUES ('__dataFactoryPipelineRunId');
    INSERT INTO @DefaultColumnList (name) VALUES ('__insertDateTimeUTC');

    SET @suppliedStructure = [utils].[CleanseString](@suppliedStructure);

    SET @Create = 'CREATE TABLE ' + QUOTENAME(@azureSqlDatabaseTableSchemaName) + '.' + QUOTENAME(@azureSqlDatabaseTableTableName);

    SELECT @Columns  = '[__rowId] bigint IDENTITY PRIMARY KEY CLUSTERED, ';

    SELECT      @Columns += columndef.name
    FROM        (   SELECT QUOTENAME(columnspec.Name) + ' varchar(max), ' as name
                    FROM OPENJSON(@suppliedStructure)
                            WITH ([Name] varchar(8000) '$.name') columnspec
                    WHERE columnspec.Name NOT IN (SELECT name FROM @DefaultColumnList)
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
    @suppliedStructure varchar(8000),    
    @sinkAzureSqlDatabaseConnectionStringSecretName varchar(8000), 
    @sinkAzureSqlDatabaseTableSchemaName varchar(8000) OUTPUT,
    @sinkAzureSqlDatabaseTableTableName varchar(8000) OUTPUT,
    @multipleMatches bit OUTPUT
AS
BEGIN

    DECLARE @foundTableSchemaName varchar(8000);
    DECLARE @foundTableTableName varchar(8000);

    EXEC [utils].[sp_GetTableBasedOnSuppliedStructure] 
        @suppliedStructure = @suppliedStructure, 
        @azureSqlDatabaseTableSchemaName = @foundTableSchemaName OUTPUT, 
        @azureSqlDatabaseTableTableName = @foundTableTableName OUTPUT, 
        @multipleMatches = @multipleMatches OUTPUT;

    IF (@foundTableSchemaName IS NULL AND @foundTableTableName IS NULL) OR -- No matching table, create new
        (@multipleMatches = 1)                          -- many matching tables, I don't know which to load, instead create another new table
    BEGIN
        EXEC utils.sp_CreateTableFromJSON 
            @suppliedStructure = @suppliedStructure,
            @azureSqlDatabaseTableSchemaName = @sinkAzureSqlDatabaseTableSchemaName OUTPUT, 
            @azureSqlDatabaseTableTableName = @sinkAzureSqlDatabaseTableTableName OUTPUT;

		SELECT  @sinkAzureSqlDatabaseTableSchemaName as sinkAzureSqlDatabaseTableSchemaName,
                @sinkAzureSqlDatabaseTableTableName as sinkAzureSqlDatabaseTableTableName,
                @multipleMatches as multipleMatches;

    END 
	ELSE
	BEGIN
		SELECT  @foundTableSchemaName as sinkAzureSqlDatabaseTableSchemaName, 
				@foundTableTableName as sinkAzureSqlDatabaseTableTableName, 
                @multipleMatches as multipleMatches;
	END
    
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
    -- Would have to be run as db_owner or other highly-priv principal, 
    
    EXEC sp_rename @OriginalObjectName, @NewTableName

    SET @sql = 'ALTER SCHEMA ' +  QUOTENAME(@NewSchemaName) + ' TRANSFER ' + @InterimObjectName + ';'
	EXEC (@sql)

    SET @sql = 'GRANT SELECT ON ' + @NewObjectName + 'TO DataLoaders;'
	EXEC (@sql) 

    SET @sql = 'GRANT INSERT ON ' + @NewObjectName + 'TO DataLoaders;'
	EXEC (@sql) 

    SET @sql = 'GRANT ALTER ON ' + @NewObjectName + 'TO DataLoaders;' -- required for TRUNCATE TABLE
	EXEC (@sql) 

END 
GO

