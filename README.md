## INSTALL STEPS:
Below assumes using the Azure Cloud Shell (PowerShell), with AZ ACCOUNT SET pointing to the correct subscription. 

          1. Step 1a: Copy the Bicep/ARM template and parameter json files to your Azure Cloud Shell folder, as well as the deploy-vmazloop.ps1 file

          1. Step 1b: Edit the parameter file as needed with subnetName, virtualNetworkId, admin username & password, diagnosticsStorageAccountName, diagnosticsStorageAccountId. 
                    ex:  PS /home/clouduser> code ./azure_deploy-template.parameters.json

          2. Step 2 - optional : Download locally and review / edit the configure-server.ps1 file to execute desired PowerShell script as desired
                    note:  this will end up being the command to execute in the VM once started as an "extension"

          3. Step 3: Create a new Resource Group in the location that matches the values in the parameters file

          4. Step 4: Deploy using the provided / uploaded PS script file
                    Command for ARM Deployment:   PS /home/clouduser> ./deploy-vmazloop.ps1
                    Command for Bicep Deployment: PS /home/clouduser> az deployment group create --resource-group <name_resource_group> --template-file azure_deploy-template.bicep --parameters azure_deploy-template.parameters.json
                 or deploy using the Azure Portal by copy & paste of the raw values from the json file contents
                    using: New > Template deployment (deploy using custom templates)
          
This does not create a public IP, so you will need to either attach one on the NIC resource, or use a Bastion Host, or connect via RDP from another VM available on the target network. 

## TROUBLESHOOTING:
* Important is having an effective route on the target subnet that can reach the FileUri specified to download the configure-server.ps1 script. For example, reaching the Azure Storage Account can be achieved various ways, such as using Service Endpoint, or ensuring there is no BGP and forced-tunneling of the default 0.0.0.0/0 route to on-premise by overriding it with a custom UDR, etc. 
* There is no support for a proxy in this example
