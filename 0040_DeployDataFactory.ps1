$parameterValues = @{ `
    dataFactoryName = "$dataFactoryName"; 
    AzureKeyVaultLinkedService_baseUrl = "https://$keyVaultName.vault.azure.net"; 
    logAnalyticsWorkspaceName = "$logAnalyticsWorkspaceName"
}

$dataFactoryDeployment = New-AzResourceGroupDeployment `
    -ResourceGroupName $resourceGroupName `
    -TemplateFile "./0040_DeployDataFactory.template.json" `
    -TemplateParameterObject $parameterValues

$dataFactoryDeployment | Out-Host

