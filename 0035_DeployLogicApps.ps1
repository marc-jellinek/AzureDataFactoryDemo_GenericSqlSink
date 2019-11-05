#$dataFactoryName = $deployment.Parameters.dataFactoryName.value
#$targetServerName = $deployment.Parameters.targetServerName.value
#$adminUser = $deployment.Parameters.adminUser.value
#$adminPassword = $deployment.Parameters.adminPassword.value
#$storageAccountName = $deployment.Outputs.storageAccountName.value
#
#$storageAccountKey = (Get-AzStorageAccountKey `
#        -ResourceGroupName $resourceGroupName `
#        -AccountName $storageAccountName | Where-Object { $_.KeyName -eq 'key1' }).Value

$parameterValuesLogicApps = @{ `
    sql_server_name = "$targetServerName.database.windows.net"; `
    sql_database_name = "TargetDatabase"; `
    sql_username = "$adminUser"; `
    sql_password = "$adminPassword"
}

$logicAppsDeployment = New-AzResourceGroupDeployment `
    -ResourceGroupName $resourceGroupName `
    -TemplateFile "./0035_LogicApp.template.json" `
    -TemplateParameterObject $parameterValuesLogicApps

$logicAppsDeployment | Out-Host

$logicAppUrl = $logicAppsDeployment.Outputs.logicAppUrl