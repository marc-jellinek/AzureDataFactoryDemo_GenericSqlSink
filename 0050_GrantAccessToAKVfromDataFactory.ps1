$dataFactoryPrincipalId = (Get-AzDataFactoryV2 -ResourceGroupName $resourceGroupName -Name $dataFactoryName).Identity.PrincipalId

$parameterValues = @{
    userObjectId = $dataFactoryPrincipalId;
    keyVaultName = $keyVaultName
}

$keyVaultSecurityDeployment = New-AzResourceGroupDeployment `
    -ResourceGroupName $resourceGroupName `
    -TemplateFile "./0050_GrantAccessToAKVfromObjectId.template.json" `
    -TemplateParameterObject $parameterValues

$keyVaultSecurityDeployment | Out-Host