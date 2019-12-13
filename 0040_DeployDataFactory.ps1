$parameterValues = @{ `
    dataFactoryName = "$dataFactoryName"; `
    keyVaultName = "$keyVaultName"; `
    keyVaultLinkedService_baseUrl = "https://$keyVaultName.vault.azure.net"; `
    logAnalyticsWorkspaceName = "$logAnalyticsWorkspaceName" `
}

$dataFactoryDeployment = New-AzResourceGroupDeployment `
    -ResourceGroupName $resourceGroupName `
    -TemplateFile "./templateAndParameters/0040_DeployDataFactory.template.json" `
    -TemplateParameterObject $parameterValues

$dataFactoryDeployment | Out-Host

./0050_GrantAccessToAKVfromDataFactory.ps1