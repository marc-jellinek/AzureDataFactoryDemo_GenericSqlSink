$deployment = New-AzResourceGroupDeployment `
    -ResourceGroupName $resourceGroupName `
    -TemplateFile "./0010_DeployAzureResources.template.json" `
    -TemplateParameterFile "./0010_DeployAzureResources.parameters.json"

$deployment | Out-Host

$keyVaultName = $deployment.Parameters.keyVaultName.value 

$targetDatabase1ServerName = $deployment.Parameters.targetDatabase1ServerName.value
$targetDatabase1DatabaseName = $deployment.Parameters.targetDatabase1DatabaseName.value 

$targetDatabase1SqlAdminUsername = $deployment.Parameters.targetDatabase1SqlAdminUsername.value 
$targetDatabase1SqlAdminPassword = $deployment.Parameters.targetDatabase1SqlAdminPassword.value 

$targetDatabase1SqlOpsUsername = $deployment.Parameters.targetDatabase1SqlOpsUsername.value 
$targetDatabase1SqlOpsPassword = $deployment.Parameters.targetDatabase1SqlOpsPassword.value 

$targetDatabase2ServerName = $deployment.Parameters.targetDatabase2ServerName.value
$targetDatabase2DatabaseName = $deployment.Parameters.targetDatabase2DatabaseName.value 

$targetDatabase2SqlAdminUsername = $deployment.Parameters.targetDatabase2SqlAdminUsername.value 
$targetDatabase2SqlAdminPassword = $deployment.Parameters.targetDatabase2SqlAdminPassword.value 

$targetDatabase2SqlOpsUsername = $deployment.Parameters.targetDatabase2SqlOpsUsername.value 
$targetDatabase2SqlOpsPassword = $deployment.Parameters.targetDatabase2SqlOpsPassword.value 

$loggingDatabaseServerName = $deployment.Parameters.loggingDatabaseServerName.value
$loggingDatabaseDatabaseName = $deployment.Parameters.loggingDatabaseDatabaseName.value

$loggingDatabaseSqlAdminUsername = $deployment.Parameters.loggingDatabaseSqlAdminUsername.value 
$loggingDatabaseSqlAdminPassword = $deployment.Parameters.loggingDatabaseSqlAdminPassword.value 

$loggingDatabaseSqlOpsUsername = $deployment.Parameters.loggingDatabaseSqlOpsUsername.value
$loggingDatabaseSqlOpsPassword = $deployment.Parameters.loggingDatabaseSqlOpsPassword.value

$dataFactoryName = $deployment.Parameters.dataFactoryName.value
$storageAccount1Name = $deployment.Parameters.storageAccount1Name.value
$storageAccount2Name = $deployment.Parameters.storageAccount2Name.value
$loggingUrl = $deployment.Outputs.loggingUrl 

$storageAccount1Key = (Get-AzStorageAccountKey `
        -ResourceGroupName $resourceGroupName `
        -AccountName $storageAccount1Name `
    | Where-Object { $_.KeyName -eq 'key1' }).Value

$storageAccount2Key = (Get-AzStorageAccountKey `
        -ResourceGroupName $resourceGroupName `
        -AccountName $storageAccount2Name `
    | Where-Object { $_.KeyName -eq 'key1' }).Value

# upload test data to blob storage accounts
$ctx = New-AzStorageContext `
    -StorageAccountName $storageAccount1Name `
    -StorageAccountKey $storageAccount1Key

Set-AzStorageBlobContent `
    -File "./0030_SourceData1.csv" `
    -Container "default" `
    -Context $ctx `
    -Force

$ctx = New-AzStorageContext `
    -StorageAccountName $storageAccount2Name `
    -StorageAccountKey $storageAccount2Key

Set-AzStorageBlobContent `
    -File "./0030_SourceData2.csv" `
    -Container "default" `
    -Context $ctx `
    -Force   

#"./0040_DeployDataFactory.ps1"