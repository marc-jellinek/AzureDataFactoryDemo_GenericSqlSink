$azureDemoResourcesDeployment = New-AzResourceGroupDeployment `
    -ResourceGroupName $resourceGroupName `
    -TemplateFile "./templateAndParameters/0010_deployAzureDemoResources.template.json" `
    -TemplateParameterFile "./templateAndParameters/0010_deployAzureDemoResources.parameters.private.json"

$azureDemoResourcesDeployment | Out-Host

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
$storageAccount1BlobServicesName = $azureDemoResourcesDeployment.Parameters.storageAccount1BlobServicesName.Value
$storageAccount1ContainerName = $azureDemoResourcesDeployment.Parameters.storageAccount1ContainerName.value

$storageAccount2Name = $azureDemoResourcesDeployment.Parameters.storageAccount2Name.value
$storageAccount2BlobServicesName = $azureDemoResourcesDeployment.Parameters.storageAccount2BlobServicesName.Value
$storageAccount2ContainerName = $azureDemoResourcesDeployment.Parameters.storageAccount2ContainerName.value

$storageAccountTempName = $azureDemoResourcesDeployment.Parameters.storageAccountTempName.value
$storageAccountTempBlobServicesName = $azureDemoResourcesDeployment.Parameters.storageAccountTempBlobServicesName.Value
$storageAccountTempContainerName = $azureDemoResourcesDeployment.Parameters.storageAccountTempContainerName.value

$storageAccountConfigName = $azureDemoResourcesDeployment.Parameters.storageAccountConfigName.value 
$storageAccountConfigBlobServicesName = $azureDemoResourcesDeployment.Parameters.storageAccountConfigBlobServicesName.Value
$storageAccountConfigContainerName = $azureDemoResourcesDeployment.Parameters.storageAccountConfigContainerName.value

$storageAccount1Key = ( `
    Get-AzStorageAccountKey `
        -ResourceGroupName $resourceGroupName `
        -AccountName $storageAccount1Name `
        | Where-Object { $_.KeyName -eq 'key1' }
).Value

$storageAccount2Key = ( `
    Get-AzStorageAccountKey `
        -ResourceGroupName $resourceGroupName `
        -AccountName $storageAccount2Name `
        | Where-Object { $_.KeyName -eq 'key1' }
).Value

$storageAccountConfigKey = (    `
    Get-AzStorageAccountKey `
        -ResourceGroupName $resourceGroupName `
        -AccountName $storageAccountConfigName `
        | Where-Object { $_.KeyName -eq 'key1' }
).Value

# upload test data to blob storage accounts
$ctx = New-AzStorageContext `
    -StorageAccountName $storageAccount1Name `
    -StorageAccountKey $storageAccount1Key

Set-AzStorageBlobContent `
    -File "./demoData/csv/singleFiles/0010_sourceData1.csv" `
    -Blob "input/csv/singleFiles/0010_sourceData1.csv" `
    -Container "$storageAccount1ContainerName" `
    -Context $ctx `
    -Properties @{"ContentType" = "text/csv"} `
    -Force

Set-AzStorageBlobContent `
    -File "./demoData/csv/singleFiles/0010_sourceData2.csv" `
    -Blob "input/csv/singleFiles/0010_sourceData2.csv" `
    -Container "$storageAccount1ContainerName" `
    -Context $ctx `
    -Properties @{"ContentType" = "text/csv"} `
    -Force

Set-AzStorageBlobContent `
    -File "./templateAndParameters/0010_deployAzureDemoResources.template.json" `
    -Blob "input/json/singleFiles/0010_deployAzureDemoResources.template.json" `
    -Container "$storageAccount1ContainerName" `
    -Context $ctx `
    -Properties @{"ContentType" = "text/json"} `
    -Force

Set-AzStorageBlobContent `
    -File "./demoData/parquet/singleFiles/userdata.parquet" `
    -Blob "input/parquet/singleFiles/userdata.parquet" `
    -Container "$storageAccount1ContainerName" `
    -Context $ctx `
    -Properties @{"ContentType" = "parquet/binary"} `
    -Force

Set-AzStorageBlobContent `
    -File "./demoData/avro/singleFiles/userdata.avro" `
    -Blob "input/avro/singleFiles/userdata.avro" `
    -Container "$storageAccount1ContainerName" `
    -Context $ctx `
    -Properties @{"ContentType" = "avro/binary"} `
    -Force

# upload configuration to config storage account
$ctx = New-AzStorageContext `
    -StorageAccountName $storageAccountConfigName `
    -StorageAccountKey $storageAccountConfigKey

Set-AzStorageBlobContent `
    -File "./demoConfig/testAllPipelines.json" `
    -Blob "config/testAllPipelines.json" `
    -Container "$storageAccountConfigContainerName" `
    -Context $ctx `
    -Properties @{"ContentType" = "text/json"} `
    -Force