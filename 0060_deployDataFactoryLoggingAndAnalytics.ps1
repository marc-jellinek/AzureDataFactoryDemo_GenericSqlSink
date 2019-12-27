$parameterValues = @{ `
    dataFactoryName = "$dataFactoryName"; `
    logAnalyticsWorkspaceName = "$dataFactoryNameLogAnalyticsWorkspace" `
}

$dataFactoryAnalyticsDeployment = New-AzResourceGroupDeployment `
    -ResourceGroupName $resourceGroupName `
    -TemplateFile "./templateAndParameters/0060_deployDataFactoryLoggingAndAnalytics.template.json" `
    -TemplateParameterObject $parameterValues

$dataFactoryAnalyticsDeployment | Out-Host