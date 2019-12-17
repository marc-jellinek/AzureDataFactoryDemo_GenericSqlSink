$deployment = New-AzResourceGroupDeployment `
    -ResourceGroupName $resourceGroupName `
    -TemplateFile "./templateAndParameters/0010_deployAzureResources.template.json" `
    -TemplateParameterFile "./templateAndParameters/0010_deployAzureResources.parameters.json"

$deployment | Out-Host

$keyVaultName = $deployment.Parameters.keyVaultName.value 

$dataFactoryName = $deployment.Parameters.dataFactoryName.value 

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

$logAnalyticsWorkspaceName = $deployment.Parameters.logAnalyticsWorkspaceName.value
$dataFactoryAnalyticsSolutionName = $deployment.Parameters.dataFactoryAnalyticsSolutionName.value 

$storageAccount1Name = $deployment.Parameters.storageAccount1Name.value
$storageAccount2Name = $deployment.Parameters.storageAccount2Name.value

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
    -File "./demoData/csv/singleFiles/0010_sourceData1.csv" `
    -Blob "csv/singleFiles/0010_sourceData1.csv" `
    -Container "default" `
    -Context $ctx `
    -Properties @{"ContentType" = "text/csv"} `
    -Force

$ctx = New-AzStorageContext `
    -StorageAccountName $storageAccount2Name `
    -StorageAccountKey $storageAccount2Key

Set-AzStorageBlobContent `
    -File "./demoData/csv/singleFiles/0010_sourceData2.csv" `
    -Blob "csv/singleFiles/0010_sourceData2.csv" `
    -Container "default" `
    -Context $ctx `
    -Properties @{"ContentType" = "text/csv"} `
    -Force   
