@description('Location for the VMs, only certain regions support zones during preview.')
param location string = 'northeurope'
param networkInterfaceName1 string = 'test-ni1198'
param enableAcceleratedNetworking bool = false
param networkSecurityGroupName string = 'test-vm-server-nsg'
param networkSecurityGroupRules array = []
param subnetName string
param virtualNetworkId string
param virtualMachineName1 string = 'test-vm-server1'
param virtualMachineComputerName1 string = 'test-vm-server1'

@description('The virtual machine\'s availability zone.')
param virtualMachineZone array
param osDiskType string = 'Premium_LRS'
param osDiskDeleteOption string = 'Delete'

@description('VM Type in Azure: Standard_B2s or Standard_A2_v2 or Standard_F2s_v2, etc.')
param virtualMachineSize string = 'Standard_B2s'
param nicDeleteOption string = 'Detach'

@description('Username for the local admin in the Virtual Machine.')
param adminUsername string

@secure()
param adminPassword string

@description('true')
param enableHotpatching bool = true

@description('Choose AutomaticByPlatform to enable Hotpatching otherwise, Manual.')
param patchMode string = 'AutomaticByPlatform'
param rebootSetting string = 'Never'
param diagnosticsStorageAccountName string
param diagnosticsStorageAccountId string

@description('licenseType must be Windows_Server to activate Azure Hybrid Benefit for Windows Server, otherwise None')
param licenseType string = 'Windows_Server'
param KeyVaultCredentialName string = ''

@description('Enable or disable key vault credential setting.')
param KeyVaultCredentialEnable bool = false
param installscripturi string
param command2exec string

@description('The name for the ip configuration of the Network Interface')
param ipConfigName string = 'ipconfig1'

@description('URI for the guest configuration extension')
param guestConfigExtTemplateLink string = 'https://catalogartifact.azureedge.net/publicartifacts/MicrosoftGuestConfiguration.ConfigurationforWindows-1.0.0/MainTemplate.json'

@description('The name of the VM for guest configuration extension')
param guestConfigExtVmName string = 'test-vm-server1'

@description('Location for guest configuration extension')
param guestConfigExtLocation string = 'northeurope'

@description('Arm Template Link for Custom Script Extension for Windows')
param customScriptExtensionTemplateLink string = 'https://catalogartifact.azureedge.net/publicartifacts/Microsoft.CustomScriptExtension-arm-2.0.57/MainTemplate.json'

@description('File URI for Custom Script Extension for Windows')
param customScriptExtensionTemplateUris string = 'https://sqlvmautobackupstorage.blob.core.windows.net/scripts/configure-server.ps1'

@description('The name of the VM for Custom Script Extension for Windows')
param customScriptExtensionVmName string = 'test-vm-server1'

@description('Location for Custom Script Extension for Windows')
param customScriptExtensionLocation string = 'northeurope'

@description('Service End Point for Diagnostics Storage Account')
param diagnosticsStorageAccountEndPoint string = 'https://core.windows.net/'

var nsgId = resourceId(resourceGroup().name, 'Microsoft.Network/networkSecurityGroups', networkSecurityGroupName)
var vnetId = virtualNetworkId
var vnetName = last(split(vnetId, '/'))
var subnetRef = '${vnetId}/subnets/${subnetName}'
var diagnosticsExtensionName = 'Microsoft.Insights.VMDiagnosticsSettings'

resource networkInterface1 'Microsoft.Network/networkInterfaces@2021-08-01' = {
  name: networkInterfaceName1
  location: location
  properties: {
    ipConfigurations: [
      {
        name: ipConfigName
        properties: {
          subnet: {
            id: subnetRef
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
    enableAcceleratedNetworking: enableAcceleratedNetworking
    networkSecurityGroup: {
      id: nsgId
    }
  }
  dependsOn: [
    networkSecurityGroup
  ]
}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2019-02-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: networkSecurityGroupRules
  }
}

resource virtualMachine1 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: virtualMachineName1
  location: location
  zones: virtualMachineZone
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: virtualMachineSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'fromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
        deleteOption: osDiskDeleteOption
      }
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-azure-edition-core'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface1.id
          properties: {
            deleteOption: nicDeleteOption
          }
        }
      ]
    }
    securityProfile: {
      encryptionAtHost: true
    }
    osProfile: {
      computerName: virtualMachineComputerName1
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
        patchSettings: {
          enableHotpatching: enableHotpatching
          patchMode: patchMode
          automaticByPlatformSettings: {
            rebootSetting: rebootSetting
          }
        }
      }
    }
    licenseType: licenseType
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: reference('Microsoft.Storage/storageAccounts/${diagnosticsStorageAccountName}', '2015-06-15').primaryEndpoints.blob
      }
    }
  }
}

module MicrosoftGuestConfiguration_ConfigurationforWindows '?' /*TODO: replace with correct path to [parameters('guestConfigExtTemplateLink')]*/ = {
  name: 'MicrosoftGuestConfiguration.ConfigurationforWindows'
  params: {
    vmName: guestConfigExtVmName
    location: guestConfigExtLocation
  }
  dependsOn: [
    virtualMachine1
  ]
}

module Microsoft_CustomScriptExtension '?' /*TODO: replace with correct path to [parameters('customScriptExtensionTemplateLink')]*/ = {
  name: 'Microsoft.CustomScriptExtension'
  params: {
    fileUris: installscripturi
    vmName: customScriptExtensionVmName
    location: customScriptExtensionLocation
  }
  dependsOn: [
    MicrosoftGuestConfiguration_ConfigurationforWindows
  ]
}

resource virtualMachineName1_diagnosticsExtension 'Microsoft.Compute/virtualMachines/extensions@2018-10-01' = {
  parent: virtualMachine1
  name: '${diagnosticsExtensionName}'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Diagnostics'
    type: 'IaaSDiagnostics'
    typeHandlerVersion: '1.5'
    autoUpgradeMinorVersion: true
    settings: {
      StorageAccount: diagnosticsStorageAccountName
      WadCfg: {
        DiagnosticMonitorConfiguration: {
          overallQuotaInMB: 5120
          Metrics: {
            resourceId: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Compute/virtualMachines/${virtualMachineName1}'
            MetricAggregation: [
              {
                scheduledTransferPeriod: 'PT1H'
              }
              {
                scheduledTransferPeriod: 'PT1M'
              }
            ]
          }
          DiagnosticInfrastructureLogs: {
            scheduledTransferLogLevelFilter: 'Error'
          }
          PerformanceCounters: {
            scheduledTransferPeriod: 'PT1M'
            PerformanceCounterConfiguration: [
              {
                counterSpecifier: '\\Processor Information(_Total)\\% Processor Time'
                unit: 'Percent'
                sampleRate: 'PT60S'
              }
              {
                counterSpecifier: '\\Processor Information(_Total)\\% Privileged Time'
                unit: 'Percent'
                sampleRate: 'PT60S'
              }
              {
                counterSpecifier: '\\Processor Information(_Total)\\% User Time'
                unit: 'Percent'
                sampleRate: 'PT60S'
              }
              {
                counterSpecifier: '\\Processor Information(_Total)\\Processor Frequency'
                unit: 'Count'
                sampleRate: 'PT60S'
              }
              {
                counterSpecifier: '\\System\\Processes'
                unit: 'Count'
                sampleRate: 'PT60S'
              }
              {
                counterSpecifier: '\\Process(_Total)\\Thread Count'
                unit: 'Count'
                sampleRate: 'PT60S'
              }
              {
                counterSpecifier: '\\Process(_Total)\\Handle Count'
                unit: 'Count'
                sampleRate: 'PT60S'
              }
              {
                counterSpecifier: '\\System\\System Up Time'
                unit: 'Count'
                sampleRate: 'PT60S'
              }
              {
                counterSpecifier: '\\System\\Context Switches/sec'
                unit: 'CountPerSecond'
                sampleRate: 'PT60S'
              }
              {
                counterSpecifier: '\\System\\Processor Queue Length'
                unit: 'Count'
                sampleRate: 'PT60S'
              }
              {
                counterSpecifier: '\\Memory\\% Committed Bytes In Use'
                unit: 'Percent'
                sampleRate: 'PT60S'
              }
              {
                counterSpecifier: '\\Memory\\Available Bytes'
                unit: 'Bytes'
                sampleRate: 'PT60S'
              }
              {
                counterSpecifier: '\\Memory\\Committed Bytes'
                unit: 'Bytes'
                sampleRate: 'PT60S'
              }
              {
                counterSpecifier: '\\Memory\\Cache Bytes'
                unit: 'Bytes'
                sampleRate: 'PT60S'
              }
              {
                counterSpecifier: '\\Memory\\Pool Paged Bytes'
                unit: 'Bytes'
                sampleRate: 'PT60S'
              }
              {
                counterSpecifier: '\\Memory\\Pool Nonpaged Bytes'
                unit: 'Bytes'
                sampleRate: 'PT60S'
              }
              {
                counterSpecifier: '\\Memory\\Pages/sec'
                unit: 'CountPerSecond'
                sampleRate: 'PT60S'
              }
              {
                counterSpecifier: '\\Memory\\Page Faults/sec'
                unit: 'CountPerSecond'
                sampleRate: 'PT60S'
              }
              {
                counterSpecifier: '\\Process(_Total)\\Working Set'
                unit: 'Count'
                sampleRate: 'PT60S'
              }
              {
                counterSpecifier: '\\Process(_Total)\\Working Set - Private'
                unit: 'Count'
                sampleRate: 'PT60S'
              }
              {
                counterSpecifier: '\\LogicalDisk(_Total)\\% Disk Time'
                unit: 'Percent'
                sampleRate: 'PT60S'
              }
              {
                counterSpecifier: '\\LogicalDisk(_Total)\\% Disk Read Time'
                unit: 'Percent'
                sampleRate: 'PT60S'
              }
              {
                counterSpecifier: '\\LogicalDisk(_Total)\\% Disk Write Time'
                unit: 'Percent'
                sampleRate: 'PT60S'
              }
              {
                counterSpecifier: '\\LogicalDisk(_Total)\\% Idle Time'
                unit: 'Percent'
                sampleRate: 'PT60S'
              }
              {
                counterSpecifier: '\\LogicalDisk(_Total)\\Disk Bytes/sec'
                unit: 'BytesPerSecond'
                sampleRate: 'PT60S'
              }
              {
                counterSpecifier: '\\LogicalDisk(_Total)\\Disk Read Bytes/sec'
                unit: 'BytesPerSecond'
                sampleRate: 'PT60S'
              }
              {
                counterSpecifier: '\\LogicalDisk(_Total)\\Disk Write Bytes/sec'
                unit: 'BytesPerSecond'
                sampleRate: 'PT60S'
              }
              {
                counterSpecifier: '\\LogicalDisk(_Total)\\Disk Transfers/sec'
                unit: 'BytesPerSecond'
                sampleRate: 'PT60S'
              }
              {
                counterSpecifier: '\\LogicalDisk(_Total)\\Disk Reads/sec'
                unit: 'BytesPerSecond'
                sampleRate: 'PT60S'
              }
              {
                counterSpecifier: '\\LogicalDisk(_Total)\\Disk Writes/sec'
                unit: 'BytesPerSecond'
                sampleRate: 'PT60S'
              }
              {
                counterSpecifier: '\\LogicalDisk(_Total)\\Avg. Disk sec/Transfer'
                unit: 'Count'
                sampleRate: 'PT60S'
              }
              {
                counterSpecifier: '\\LogicalDisk(_Total)\\Avg. Disk sec/Read'
                unit: 'Count'
                sampleRate: 'PT60S'
              }
              {
                counterSpecifier: '\\LogicalDisk(_Total)\\Avg. Disk sec/Write'
                unit: 'Count'
                sampleRate: 'PT60S'
              }
              {
                counterSpecifier: '\\LogicalDisk(_Total)\\Avg. Disk Queue Length'
                unit: 'Count'
                sampleRate: 'PT60S'
              }
              {
                counterSpecifier: '\\LogicalDisk(_Total)\\Avg. Disk Read Queue Length'
                unit: 'Count'
                sampleRate: 'PT60S'
              }
              {
                counterSpecifier: '\\LogicalDisk(_Total)\\Avg. Disk Write Queue Length'
                unit: 'Count'
                sampleRate: 'PT60S'
              }
              {
                counterSpecifier: '\\LogicalDisk(_Total)\\% Free Space'
                unit: 'Percent'
                sampleRate: 'PT60S'
              }
              {
                counterSpecifier: '\\LogicalDisk(_Total)\\Free Megabytes'
                unit: 'Count'
                sampleRate: 'PT60S'
              }
              {
                counterSpecifier: '\\Network Interface(*)\\Bytes Total/sec'
                unit: 'BytesPerSecond'
                sampleRate: 'PT60S'
              }
              {
                counterSpecifier: '\\Network Interface(*)\\Bytes Sent/sec'
                unit: 'BytesPerSecond'
                sampleRate: 'PT60S'
              }
              {
                counterSpecifier: '\\Network Interface(*)\\Bytes Received/sec'
                unit: 'BytesPerSecond'
                sampleRate: 'PT60S'
              }
              {
                counterSpecifier: '\\Network Interface(*)\\Packets/sec'
                unit: 'BytesPerSecond'
                sampleRate: 'PT60S'
              }
              {
                counterSpecifier: '\\Network Interface(*)\\Packets Sent/sec'
                unit: 'BytesPerSecond'
                sampleRate: 'PT60S'
              }
              {
                counterSpecifier: '\\Network Interface(*)\\Packets Received/sec'
                unit: 'BytesPerSecond'
                sampleRate: 'PT60S'
              }
              {
                counterSpecifier: '\\Network Interface(*)\\Packets Outbound Errors'
                unit: 'Count'
                sampleRate: 'PT60S'
              }
              {
                counterSpecifier: '\\Network Interface(*)\\Packets Received Errors'
                unit: 'Count'
                sampleRate: 'PT60S'
              }
            ]
          }
          WindowsEventLog: {
            scheduledTransferPeriod: 'PT1M'
            DataSource: [
              {
                name: 'Application!*[System[(Level = 1 or Level = 2 or Level = 3)]]'
              }
              {
                name: 'Security!*[System[band(Keywords,4503599627370496)]]'
              }
              {
                name: 'System!*[System[(Level = 1 or Level = 2 or Level = 3)]]'
              }
            ]
          }
        }
      }
    }
    protectedSettings: {
      storageAccountName: diagnosticsStorageAccountName
      storageAccountKey: first(listKeys(diagnosticsStorageAccountId, '2021-01-01').keys).value
      storageAccountEndPoint: diagnosticsStorageAccountEndPoint
    }
  }
  dependsOn: [
    Microsoft_CustomScriptExtension
  ]
}

output adminUsername string = adminUsername