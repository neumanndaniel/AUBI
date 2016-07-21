# Azure Usage and Billing Portal
cd $PSScriptRoot

$ResourceGroupName="AUBI"
$ARMtemplate=cat .\CreateAzureServicesScriptResources.parameters.json|ConvertFrom-Json

$LoginData=Login-AzureRmAccount

Get-AzureRmSubscription|Out-GridView -PassThru -Title "Select the Azure subscription you want to use for the deployment:"|Select-AzureRmSubscription

$RegionTemp=Get-AzureRmLocation|Out-GridView -PassThru -Title "Select the Azure region you want to create the resource group in:"
$Region=$RegionTemp.Location

New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Region -Force -Verbose

$Credential=Get-Credential -Message "SQL DB user name and password."

New-AzureRmResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile .\CreateAzureServicesScriptResources.json -TemplateParameterFile .\CreateAzureServicesScriptResources.parameters.json -sqlAdministratorLogin $Credential.UserName -sqlAdministratorLoginPassword $Credential.Password -Verbose

$storageKey = Get-AzureRmStorageAccountKey -Name $ARMtemplate.parameters.storageAccountName.value -ResourceGroupName $ResourceGroupName
$tenantID = Get-AzureRmTenant|Where-Object{$_.TenantId -ne $LoginData.Context.Tenant.TenantId}

Write-Host ("Parameters to be used in the project settings / configuration files.") -foreground Green
Write-Host ("Please update parameters in Web.config and App.config with the ones below.") -foreground Green
Write-Host ("====================================================================`n") -foreground Green
Write-Host "ASQLConn ConnectionString: " -foreground Green –NoNewLine
Write-Host ("Data Source=tcp:" + $ARMtemplate.parameters.sqlServerName.value + ".database.windows.net,1433;Initial Catalog=" + $ARMtemplate.parameters.sqlDatabaseName.value + ";User Id=" + $Credential.UserName + "@" + $ARMtemplate.parameters.sqlServerName.value + ";Password="+ $Credential.GetNetworkCredential().password +";") -foreground Red 
Write-Host "ida:TenantId: " -foreground Green –NoNewLine
Write-Host $tenantID -foreground Red 
Write-Host "AzureWebJobsDashboard: " -foreground Green –NoNewLine
Write-Host ("DefaultEndpointsProtocol=https;AccountName=" + $ARMtemplate.parameters.storageAccountName.value + ";AccountKey=" + $storageKey[0].Value) -foreground Red 
Write-Host "AzureWebJobsStorage: " -foreground Green –NoNewLine
Write-Host ("DefaultEndpointsProtocol=https;AccountName=" + $ARMtemplate.parameters.storageAccountName.value + ";AccountKey=" + $storageKey[0].Value) -foreground Red 