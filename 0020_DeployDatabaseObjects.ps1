# Create operational user in logging as admin, 
# grant all rights to operational user in utils schema, 
# grant EXEC to Audit.InsertOperationsEventLog
Invoke-Sqlcmd `
    -ServerInstance "tcp:$loggingDatabaseServerName.database.windows.net" `
    -Database "$loggingDatabaseDatabaseName" `
    -Username $loggingDatabaseSqlAdminUsername `
    -Password $loggingDatabaseSqlAdminPassword `
    -InputFile "./0020_DeployLoggingDatabaseObjects.sql"

Invoke-Sqlcmd `
    -ServerInstance "tcp:$loggingDatabaseServerName.database.windows.net" `
    -Database "$loggingDatabaseDatabaseName" `
    -Username $loggingDatabaseSqlAdminUsername `
    -Password $loggingDatabaseSqlAdminPassword `
    -Query "CREATE USER $loggingDatabaseSqlOpsUserName WITH PASSWORD='$loggingDatabaseSqlOpsPassword'"

Invoke-Sqlcmd `
    -ServerInstance "tcp:$loggingDatabaseServerName.database.windows.net" `
    -Database "$loggingDatabaseDatabaseName" `
    -Username $loggingDatabaseSqlAdminUsername `
    -Password $loggingDatabaseSqlAdminPassword `
    -Query "ALTER ROLE LoggingUsers ADD MEMBER $loggingDatabaseSqlOpsUsername"    

# Create operational user in TargetDB1 as admin
# Create schema [utils]
# grant operational user CONTROL on schema [utils]

Invoke-Sqlcmd `
    -ServerInstance "tcp:$targetDatabase1ServerName.database.windows.net" `
    -Database "$targetDatabase1DatabaseName" `
    -Username $targetDatabase1SqlAdminUsername `
    -Password $targetDatabase1SqlAdminPassword `
    -InputFile "./0020_DeployTargetDatabaseObjects.sql"

Invoke-Sqlcmd `
    -ServerInstance "tcp:$targetDatabase1ServerName.database.windows.net" `
    -Database "$targetDatabase1DatabaseName" `
    -Username $targetDatabase1SqlAdminUsername `
    -Password $targetDatabase1SqlAdminPassword `
    -Query "CREATE USER [$targetDatabase1SqlOpsUsername] WITH PASSWORD='$targetDatabase1SqlOpsPassword'"

Invoke-Sqlcmd `
    -ServerInstance "tcp:$targetDatabase1ServerName.database.windows.net" `
    -Database "$targetDatabase1DatabaseName" `
    -Username $targetDatabase1SqlAdminUsername `
    -Password $targetDatabase1SqlAdminPassword `
    -Query "ALTER ROLE [DataLoaders] ADD MEMBER [$targetDatabase1SqlOpsUsername]"

# Create operational user in TargetDB2 as admin
# Create schema [utils]
# grant operational user access on schema [utils]

Invoke-Sqlcmd `
    -ServerInstance "tcp:$targetDatabase2ServerName.database.windows.net" `
    -Database "$targetDatabase2DatabaseName" `
    -Username $targetDatabase2SqlAdminUsername `
    -Password $targetDatabase2SqlAdminPassword `
    -InputFile "./0020_DeployTargetDatabaseObjects.sql"

Invoke-Sqlcmd `
    -ServerInstance "tcp:$targetDatabase2ServerName.database.windows.net" `
    -Database "$targetDatabase2DatabaseName" `
    -Username $targetDatabase2SqlAdminUsername `
    -Password $targetDatabase2SqlAdminPassword `
    -Query "CREATE USER [$targetDatabase2SqlOpsUsername] WITH PASSWORD='$targetDatabase2SqlOpsPassword'"

Invoke-Sqlcmd `
    -ServerInstance "tcp:$targetDatabase2ServerName.database.windows.net" `
    -Database "$targetDatabase2DatabaseName" `
    -Username $targetDatabase2SqlAdminUsername `
    -Password $targetDatabase2SqlAdminPassword `
    -Query "ALTER ROLE [DataLoaders] ADD MEMBER [$targetDatabase2SqlOpsUsername]"
