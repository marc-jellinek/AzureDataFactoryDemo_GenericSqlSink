$parameterValues = @{ `
    dataFactoryName = "$dataFactoryName"; `
    logAnalyticsWorkspaceName = "$dataFactoryName LogAnalyticsWorkspace" `
}

$dataFactoryDeployment = New-AzResourceGroupDeployment `
    -ResourceGroupName $resourceGroupName `
    -TemplateFile "./templateAndParameters/0060_deployDataFactoryLoggingAndAnalytics.template.json" `
    -TemplateParameterObject $parameterValues

$dataFactoryDeployment | Out-Host

& "./0050_GrantAccessToAKVfromDataFactory.ps1"