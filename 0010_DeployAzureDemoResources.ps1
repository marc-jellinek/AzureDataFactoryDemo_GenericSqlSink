$deployment = New-AzResourceGroupDeployment `
    -ResourceGroupName $resourceGroupName `
    -TemplateFile "./templateAndParameters/0010_deployAzureDemoResources.template.json" `
    -TemplateParameterFile "./templateAndParameters/0010_deployAzureDemoResources.parameters.json"

$deployment | Out-Host

$keyVaultName = $deployment.Parameters.keyVaultName.value 

$dataFactoryName = $deployment.Parameters.dataFactoryName.value 

$database1ServerName = $deployment.Parameters.database1ServerName.value
$database1DatabaseName = $deployment.Parameters.database1DatabaseName.value 

$database1SqlAdminUsername = $deployment.Parameters.database1SqlAdminUsername.value 
$database1SqlAdminPassword = $deployment.Parameters.database1SqlAdminPassword.value 

$database1SqlOpsUsername = $deployment.Parameters.database1SqlOpsUsername.value 
$database1SqlOpsPassword = $deployment.Parameters.database1SqlOpsPassword.value 

$database2ServerName = $deployment.Parameters.database2ServerName.value
$database2DatabaseName = $deployment.Parameters.database2DatabaseName.value 

$database2SqlAdminUsername = $deployment.Parameters.database2SqlAdminUsername.value 
$database2SqlAdminPassword = $deployment.Parameters.database2SqlAdminPassword.value 

$database2SqlOpsUsername = $deployment.Parameters.database2SqlOpsUsername.value 
$database2SqlOpsPassword = $deployment.Parameters.database2SqlOpsPassword.value 

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
