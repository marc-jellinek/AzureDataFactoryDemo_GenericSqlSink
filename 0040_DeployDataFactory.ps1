$parameterValues = @{ `
    factoryName = "$dataFactoryName"; 
}

$dataFactoryDeployment = New-AzResourceGroupDeployment `
    -ResourceGroupName $resourceGroupName `
    -TemplateFile "./0040_DeployDataFactory.template.json" `
    -TemplateParameterObject $parameterValues

$dataFactoryDeployment | Out-Host