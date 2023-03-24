# INSTALL STEPS (ARM & BICEP)

## BICEP DEPLOYMENT:
Below assumes using the Azure Cloud Shell (PowerShell), with AZ ACCOUNT SET pointing to the correct subscription. 

* Step 1a: Copy the Bicep template and parameter json files to your Azure Cloud Shell folder

* Step 1b: Edit the parameter file as needed with subnetName, virtualNetworkId, admin username & password, diagnosticsStorageAccountName, diagnosticsStorageAccountId.
```Bash
ex:  PS /home/clouduser> code ./azure_deploy-template.parameters.json
```
* Step 2 - optional : Download locally and review / edit the configure-server.ps1 file to execute desired PowerShell script as desired
                    note:  this will end up being the command to execute in the VM once started as an "extension"

* Step 3: Create a new Resource Group in the location that matches the values in the parameters file

* Step 4: Deploy using the provided / uploaded script file
```Bash
PS /home/clouduser> az deployment group create --resource-group <name_resource_group> --template-file azure_deploy-template.bicep --parameters azure_deploy-template.parameters.json
```

This does not create a public IP, so you will need to either attach one on the NIC resource, or use a Bastion Host, or connect via RDP from another VM available on the target network. 


## ARM DEPLOYMENT:
Below assumes using the Azure Cloud Shell (PowerShell), with AZ ACCOUNT SET pointing to the correct subscription. 

* Step 1a: Copy the ARM template and parameter json files to your Azure Cloud Shell folder, as well as the deploy-vmazloop.ps1 file

* Step 1b: Edit the parameter file as needed with subnetName, virtualNetworkId, admin username & password, diagnosticsStorageAccountName, diagnosticsStorageAccountId.
```Bash
ex:  PS /home/clouduser> code ./azure_deploy-template.parameters.json
```

* Step 2 - optional : Download locally and review / edit the configure-server.ps1 file to execute desired PowerShell script as desired
                    note:  this will end up being the command to execute in the VM once started as an "extension"

* Step 3: Create a new Resource Group in the location that matches the values in the parameters file

* Step 4: Deploy using the provided / uploaded PS script file
```Bash
PS /home/clouduser> ./deploy-vmazloop.ps1
```
or 
Deploy using the Azure Portal by uploading the ARM json file & parameters contents
using: 
```Bash
New > Template deployment (Deploy using custom templates)
```
          
This does not create a public IP, so you will need to either attach one on the NIC resource, or use a Bastion Host, or connect via RDP from another VM available on the target network. 

## TROUBLESHOOTING:
* Important is having an effective route on the target subnet that can reach the FileUri specified to download the configure-server.ps1 script. For example, reaching the Azure Storage Account can be achieved various ways, such as using Service Endpoint, or ensuring there is no BGP and forced-tunneling of the default 0.0.0.0/0 route to on-premise by overriding it with a custom UDR, etc. 
* There is no support for a proxy in this example
