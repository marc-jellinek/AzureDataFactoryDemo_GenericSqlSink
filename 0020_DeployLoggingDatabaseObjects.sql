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

CREATE OR ALTER PROCEDURE audit.InsertOperationsEventLog
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

CREATE ROLE [LoggingUsers]
GO

GRANT INSERT ON [audit].[OperationsEventLog] TO [LoggingUsers]
GO

GRANT EXECUTE ON [audit].[InsertOperationsEventLog] TO [LoggingUsers]
GO