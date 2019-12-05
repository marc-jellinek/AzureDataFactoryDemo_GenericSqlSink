$dataFactoryName = 'mdjDataFactory'

$parameterValues = @{ `
    dataFactoryName = "$dataFactoryName"; 
    AzureKeyVaultLinkedService_baseUrl = "https://$keyVaultName.vault.azure.net"
}

$dataFactoryDeployment = New-AzResourceGroupDeployment `
    -ResourceGroupName $resourceGroupName `
    -TemplateFile "./0040_DeployDataFactory.template.json" `
    -TemplateParameterObject $parameterValues

# Get deploying user's userObjectId
# grant it access to the Key Vault 
# hardcoded in the template parameter file, 
# make it dynamic inside the template or look up the current user

$dataFactoryDeployment | Out-Host

