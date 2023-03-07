# 1) ENSURE THE TARGET RESOURCE GROUP TO DEPLOY INTO EXISTS
# 2) REVIEW THE DEPLOYMENT NAME - CHANGE IF NEW DEPLOYMENT vs DELTA
param(
 [Parameter(Mandatory=$True)]
 [string]
 $resourceGroupName,
 [Parameter(Mandatory=$False)]
 [string]
 $deploymentName
)

if(!($deploymentName)){
    $deploymentName = "SQLvmAZloop1"
} else {

}

$templateFilePath = "./azure_deploy-template.json"
$parametersFilePath = "./azure_deploy-template.parameters.json"
New-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName -Name $deploymentName -TemplateFile $templateFilePath -TemplateParameterFile $parametersFilePath;

