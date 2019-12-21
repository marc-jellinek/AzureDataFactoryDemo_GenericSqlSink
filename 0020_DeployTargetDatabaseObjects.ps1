# Create operational user in TargetDB1 as admin
# Create schema [utils]
# grant operational user rights on schema [utils] through group DataLoaders

Invoke-Sqlcmd `
    -ServerInstance "tcp:$targetDatabase1ServerName.database.windows.net" `
    -Database "$targetDatabase1DatabaseName" `
    -Username $targetDatabase1SqlAdminUsername `
    -Password "z^43SFZv6^f3" `
    -InputFile "./sqlFiles/0020_DeployTargetDatabaseObjects.sql"

Invoke-Sqlcmd `
    -ServerInstance "tcp:$targetDatabase1ServerName.database.windows.net" `
    -Database "$targetDatabase1DatabaseName" `
    -Username $targetDatabase1SqlAdminUsername `
    -Password "z^43SFZv6^f3" `
    -Query "CREATE USER [$targetDatabase1SqlOpsUsername] WITH PASSWORD='pPK^d5KajrN4'"

Invoke-Sqlcmd `
    -ServerInstance "tcp:$targetDatabase1ServerName.database.windows.net" `
    -Database "$targetDatabase1DatabaseName" `
    -Username $targetDatabase1SqlAdminUsername `
    -Password "z^43SFZv6^f3" `
    -Query "ALTER ROLE [DataLoaders] ADD MEMBER [$targetDatabase1SqlOpsUsername]"

# Create operational user in TargetDB2 as admin
# Create schema [utils]
# grant operational user rights on schema [utils] through group DataLoaders

Invoke-Sqlcmd `
    -ServerInstance "tcp:$targetDatabase2ServerName.database.windows.net" `
    -Database "$targetDatabase2DatabaseName" `
    -Username $targetDatabase2SqlAdminUsername `
    -Password "UcQpOwR8v2l@" `
    -InputFile "./sqlFiles/0020_DeployTargetDatabaseObjects.sql"

Invoke-Sqlcmd `
    -ServerInstance "tcp:$targetDatabase2ServerName.database.windows.net" `
    -Database "$targetDatabase2DatabaseName" `
    -Username $targetDatabase2SqlAdminUsername `
    -Password "UcQpOwR8v2l@" `
    -Query "CREATE USER [$targetDatabase2SqlOpsUsername] WITH PASSWORD='3%0Y&W1%6rct'"

Invoke-Sqlcmd `
    -ServerInstance "tcp:$targetDatabase2ServerName.database.windows.net" `
    -Database "$targetDatabase2DatabaseName" `
    -Username $targetDatabase2SqlAdminUsername `
    -Password "UcQpOwR8v2l@" `
    -Query "ALTER ROLE [DataLoaders] ADD MEMBER [$targetDatabase2SqlOpsUsername]"
