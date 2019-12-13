# Create operational user in TargetDB1 as admin
# Create schema [utils]
# grant operational user rights on schema [utils] through group DataLoaders

Invoke-Sqlcmd `
    -ServerInstance "tcp:$targetDatabase1ServerName.database.windows.net" `
    -Database "$targetDatabase1DatabaseName" `
    -Username $targetDatabase1SqlAdminUsername `
    -Password $targetDatabase1SqlAdminPassword `
    -InputFile "./sqlFiles/0020_DeployTargetDatabaseObjects.sql"

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
# grant operational user rights on schema [utils] through group DataLoaders

Invoke-Sqlcmd `
    -ServerInstance "tcp:$targetDatabase2ServerName.database.windows.net" `
    -Database "$targetDatabase2DatabaseName" `
    -Username $targetDatabase2SqlAdminUsername `
    -Password $targetDatabase2SqlAdminPassword `
    -InputFile "./sqlFiles/0020_DeployTargetDatabaseObjects.sql"

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
