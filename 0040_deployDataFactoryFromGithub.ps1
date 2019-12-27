$dataFactoryParameterValues = @{ `
    dataFactoryName = "$dataFactoryName"; `
    gitAccountName = "marc-jellinek"; `
    gitRepositoryName = "AzureDataFactoryDemo_GenericSqlSink"; `
    gitBranchName = "master"; `
    gitRootFolder = "azuredatafactory"; `
}

$dataFactoryDeployment = New-AzResourceGroupDeployment `
    -ResourceGroupName $resourceGroupName `
    -TemplateFile "./templateAndParameters/0040_deployDataFactoryFromGithub.template.json" `
    -TemplateParameterObject $dataFactoryParameterValues

$dataFactoryDeployment | Out-Host

& "./0050_GrantAccessToAKVfromDataFactory.ps1" 