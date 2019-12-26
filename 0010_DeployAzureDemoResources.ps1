$azureDemoResourcesDeployment = New-AzResourceGroupDeployment `
    -ResourceGroupName $resourceGroupName `
    -TemplateFile "./templateAndParameters/0010_deployAzureDemoResources.template.json" `
    -TemplateParameterFile "./templateAndParameters/0010_deployAzureDemoResources.parameters.json"

$deployment | Out-Host

$keyVaultName = $azureDemoResourcesDeployment.Parameters.keyVaultName.value 

$dataFactoryName = $azureDemoResourcesDeployment.Parameters.dataFactoryName.value 

$database1ServerName = $azureDemoResourcesDeployment.Parameters.database1ServerName.value
$database1DatabaseName = $azureDemoResourcesDeployment.Parameters.database1DatabaseName.value 

$database1SqlAdminUsername = $azureDemoResourcesDeployment.Parameters.database1SqlAdminUsername.value 
$database1SqlAdminPassword = $azureDemoResourcesDeployment.Parameters.database1SqlAdminPassword.value 

$database1SqlOpsUsername = $azureDemoResourcesDeployment.Parameters.database1SqlOpsUsername.value 
$database1SqlOpsPassword = $azureDemoResourcesDeployment.Parameters.database1SqlOpsPassword.value 

$database2ServerName = $azureDemoResourcesDeployment.Parameters.database2ServerName.value
$database2DatabaseName = $azureDemoResourcesDeployment.Parameters.database2DatabaseName.value 

$database2SqlAdminUsername = $azureDemoResourcesDeployment.Parameters.database2SqlAdminUsername.value 
$database2SqlAdminPassword = $azureDemoResourcesDeployment.Parameters.database2SqlAdminPassword.value 

$database2SqlOpsUsername = $azureDemoResourcesDeployment.Parameters.database2SqlOpsUsername.value 
$database2SqlOpsPassword = $azureDemoResourcesDeployment.Parameters.database2SqlOpsPassword.value 

$storageAccount1Name = $azureDemoResourcesDeployment.Parameters.storageAccount1Name.value
$storageAccount2Name = $azureDemoResourcesDeployment.Parameters.storageAccount2Name.value

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
    -Blob "input/csv/singleFiles/0010_sourceData1.csv" `
    -Container "default" `
    -Context $ctx `
    -Properties @{"ContentType" = "text/csv"} `
    -Force

$ctx = New-AzStorageContext `
    -StorageAccountName $storageAccount2Name `
    -StorageAccountKey $storageAccount2Key

Set-AzStorageBlobContent `
    -File "./demoData/csv/singleFiles/0010_sourceData2.csv" `
    -Blob "input/csv/singleFiles/0010_sourceData2.csv" `
    -Container "default" `
    -Context $ctx `
    -Properties @{"ContentType" = "text/csv"} `
    -Force   
