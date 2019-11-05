$deployment = New-AzResourceGroupDeployment `
    -ResourceGroupName $resourceGroupName `
    -TemplateFile "./0010_DeployAzureResources.template.json" `
    -TemplateParameterFile "./0010_DeployAzureResources.parameters.json"

$deployment | Out-Host

$dataFactoryName = $deployment.Parameters.dataFactoryName.value
$targetServerName = $deployment.Parameters.targetServerName.value
$adminUser = $deployment.Parameters.adminUser.value
$adminPassword = $deployment.Parameters.adminPassword.value
$storageAccountName = $deployment.Outputs.storageAccountName.value

$storageAccountKey = (Get-AzStorageAccountKey `
        -ResourceGroupName $resourceGroupName `
        -AccountName $storageAccountName | Where-Object { $_.KeyName -eq 'key1' }).Value

# upload test data to blob storage account
$ctx = New-AzStorageContext `
    -StorageAccountName $storageAccountName `
    -StorageAccountKey $storageAccountKey

Set-AzStorageBlobContent `
    -File "./0030_SourceData1.csv" `
    -Container "default" `
    -Context $ctx

Set-AzStorageBlobContent `
    -File "./0030_SourceData2.csv" `
    -Container "default" `
    -Context $ctx    

$data = @{  `
    "storageAccountName" = $storageAccountName; `
    "storageAccountKey" = $storageAccountKey; `
    "targetServerName" = $targetServerName; `
    "dataFactoryName" = $dataFactoryName; `
    "adminUser" = $adminUser;
    "adminPassword" = $adminPassword;
    "location" = $location
}

$data | Out-Host 

#"./0040_DeployDataFactory.ps1"