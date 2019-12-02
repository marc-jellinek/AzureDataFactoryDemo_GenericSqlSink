$parameterValues = @{ `
    dataFactoryName = "$dataFactoryName"; 
    AzureKeyVaultLinkedService_baseUrl = "$keyVaultName.vault.azure.net"
}

$dataFactoryDeployment = New-AzResourceGroupDeployment `
    -ResourceGroupName "AzDataFactoryDemo_GenericSqlSink" `
    -TemplateFile "./arm_template.json" `
    -TemplateParameterObject $parameterValues

$dataFactoryDeployment | Out-Host