# Create operational user in DB1 as admin
# Create schema [utils]
# grant operational user rights on schema [utils] through group DataLoaders

Invoke-Sqlcmd `
    -ServerInstance "tcp:$database1ServerName.database.windows.net" `
    -Database "$database1DatabaseName" `
    -Username $database1SqlAdminUsername `
    -Password "z^43SFZv6^f3" `
    -InputFile "./sqlFiles/0020_deploySinkAzureSqlDatabaseObjects.sql"

Invoke-Sqlcmd `
    -ServerInstance "tcp:$database1ServerName.database.windows.net" `
    -Database "$database1DatabaseName" `
    -Username $database1SqlAdminUsername `
    -Password "z^43SFZv6^f3" `
    -Query "CREATE USER [$database1SqlOpsUsername] WITH PASSWORD='pPK^d5KajrN4'"

Invoke-Sqlcmd `
    -ServerInstance "tcp:$database1ServerName.database.windows.net" `
    -Database "$database1DatabaseName" `
    -Username $database1SqlAdminUsername `
    -Password "z^43SFZv6^f3" `
    -Query "ALTER ROLE [DataLoaders] ADD MEMBER [$database1SqlOpsUsername]"

# Create operational user in DB2 as admin
# Create schema [utils]
# grant operational user rights on schema [utils] through group DataLoaders

Invoke-Sqlcmd `
    -ServerInstance "tcp:$database2ServerName.database.windows.net" `
    -Database "$database2DatabaseName" `
    -Username $database2SqlAdminUsername `
    -Password "UcQpOwR8v2l@" `
    -InputFile "./sqlFiles/0020_deploySinkAzureSqlDatabaseObjects.sql"

Invoke-Sqlcmd `
    -ServerInstance "tcp:$database2ServerName.database.windows.net" `
    -Database "$database2DatabaseName" `
    -Username $database2SqlAdminUsername `
    -Password "UcQpOwR8v2l@" `
    -Query "CREATE USER [$database2SqlOpsUsername] WITH PASSWORD='3%0Y&W1%6rct'"

Invoke-Sqlcmd `
    -ServerInstance "tcp:$database2ServerName.database.windows.net" `
    -Database "$database2DatabaseName" `
    -Username $database2SqlAdminUsername `
    -Password "UcQpOwR8v2l@" `
    -Query "ALTER ROLE [DataLoaders] ADD MEMBER [$database2SqlOpsUsername]"
