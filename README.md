# bicep-templates
Azure の様々な検証環境を bicep ファイルとしてまとめています。

# How to
Azure CLI
~~~
az group create --name <resource-group-name> --location <resource-group-location>
az deployment group create --resource-group <resource-group-name> --template-file <path-to-bicep>
~~~
Azure Powershell
~~~
New-AzResourceGroup -Name <resource-group-name> -Location <resource-group-location>
New-AzResourceGroupDeployment -ResourceGroupName <resource-group-name> -TemplateFile <path-to-bicep>
~~~

# parameter.json
parameter.json からパラメーター指定したい場合は、VM のパスワード等の固有の情報を含むため、必要に応じて変更しご利用ください。
