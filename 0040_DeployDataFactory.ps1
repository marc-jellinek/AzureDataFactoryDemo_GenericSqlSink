$parameterValues = @{ `
    factoryName = $data.dataFactoryName; `
    TargetDatabase_connectionString = "Server=tcp:$targetServerName.database.windows.net,1433;Initial Catalog=TargetDatabase;Persist Security Info=False;User ID=$adminUser;Password=$adminPassword;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"; `
    SourceBlobStorageAccount_connectionString = "DefaultEndpointsProtocol=https;AccountName=$storageAccountName;AccountKey=$storageAccountKey;EndpointSuffix=core.windows.net"
}

$dataFactoryDeployment = New-AzResourceGroupDeployment `
    -ResourceGroupName $resourceGroupName `
    -TemplateFile "./0040_DeployDataFactory.template.json" `
    -TemplateParameterObject $parameterValues

$dataFactoryDeployment | Out-Host