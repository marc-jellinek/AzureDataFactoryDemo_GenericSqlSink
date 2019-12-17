$parameterValues = @{ `
    dataFactoryName = "$dataFactoryName"; `
    keyVaultLinkedService_baseUrl = "https://$keyVaultName.vault.azure.net"; `
}

$dataFactoryDeployment = New-AzResourceGroupDeployment `
    -ResourceGroupName $resourceGroupName `
    -TemplateFile "./templateAndParameters/0040_DeployDataFactory.template.json" `
    -TemplateParameterObject $parameterValues

$dataFactoryDeployment | Out-Host

& "./0050_GrantAccessToAKVfromDataFactory.ps1" 