$parameterValues = @{ `
    dataFactoryName = "$dataFactoryName"; 
}

$dataFactoryDeployment `
    = New-AzResourceGroupDeployment `
        -ResourceGroupName $resourceGroupName `
        -TemplateFile "./0040_DeployDataFactory.template.json" `
        -TemplateParameterObject $parameterValues

#$dataFactoryDeployment `
#    = New-AzResourceGroupDeployment `
#    -ResourceGroupName $resourceGroupName `
#    -TemplateFile "./0040_DeployDataFactory.template.json" `
#    -TemplateParameterFile "./0040_DeployDataFactory.parameters.json"

$dataFactoryDeployment | Out-Host