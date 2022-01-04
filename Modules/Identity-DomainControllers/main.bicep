@secure()
param domainJoinPassword string
@secure()
param adminUsername string
@secure()
param adminPassword string
@secure()
param domainJoinUsername string

param domainControllerName string
param addressSpace string
param logAnalyticsWorkspaceName string
param logAnalyticsResourceGroup string
param domainControllerSubnetId string
param domainFQDN string
param orgUnitPath string
param location string

// This should return an array of something like ['10', '100', '0', '0'] which makes it easier to use for subnetting below
var addressSpaceOctets = split(addressSpace, '.')

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: logAnalyticsWorkspaceName
  scope: resourceGroup(logAnalyticsResourceGroup)
}

resource dcSubnetNetworkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: 'dc-subnet-nsg-${location}'
  location: location
  properties: {
    securityRules: []
  }
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2020-11-01' = {
  name: '${domainControllerName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconf'
        properties: {
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: domainControllerSubnetId
          }
          privateIPAddress: '${addressSpaceOctets[0]}.${addressSpaceOctets[1]}.4.4'
        }
      }
    ]
  }
}

resource windowsVM 'Microsoft.Compute/virtualMachines@2021-07-01' = {
  name: domainControllerName
  location: location
  properties: {
    licenseType: 'Windows_Server'

    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    osProfile: {
      computerName: toUpper(domainControllerName)
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: 'latest'
      }
      osDisk: {
        name: '${domainControllerName}-osDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}

resource networkWatcherAgentExtension 'Microsoft.Compute/virtualMachines/extensions@2021-07-01' = {
  name: 'AzureNetworkWatcherExtension'
  parent: windowsVM
  location: location
  properties: {
    publisher: 'Microsoft.Azure.NetworkWatcher'
    type: 'NetworkWatcherAgentWindows'
    typeHandlerVersion: '1.4'
    autoUpgradeMinorVersion: true
    settings: {}
  }
}

resource IaaSAntimalwareExtension 'Microsoft.Compute/virtualMachines/extensions@2021-07-01' = {
  name: 'IaaSAntimalware'
  parent: windowsVM
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Security'
    type: 'IaaSAntimalware'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      AntimalwareEnabled: true
      RealtimeProtectionEnabled: true
      ScheduledScanSettings: {
        isEnabled: true
        day: '7'
        time: '120'
        scanType: 'Quick'
      }
      Exclusions: {
        Extensions: ''
        Paths: ''
        Processes: ''
      }
    }
  }
}

resource activeDirectoryDomainJoinExtension 'Microsoft.Compute/virtualMachines/extensions@2021-07-01' = {
  name: 'joindomain'
  parent: windowsVM
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      Name: domainFQDN
      User: '${domainJoinUsername}@${domainFQDN}'
      Restart: 'true'
      Options: 3
      OUPATH: orgUnitPath
    }
    protectedSettings: {
      Password: domainJoinPassword
    }
  }
}

resource storageaccount 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: 'vmdiag${uniqueString(resourceGroup().id)}'
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_GRS'
  }
  tags: {
    'usage': 'VM and Perf Diagnostics'
  }
}

// resource azureMonitorWindowsAgentExtension 'Microsoft.Compute/virtualMachines/extensions@2021-07-01' = {
//   name: 'AzureMonitorWindowsAgent'
//   parent: windowsVM
//   location: location
//   properties: {
//     publisher: 'Microsoft.Azure.Monitor'
//     type: 'AzureMonitorWindowsAgent'
//     typeHandlerVersion: '1.0'
//     autoUpgradeMinorVersion: true
//     settings: {}
//   }
// }

// resource AADLoginExtension 'Microsoft.Compute/virtualMachines/extensions@2021-07-01' = {
//   name: 'AADLogin'
//   parent: windowsVM
//   location: location
//   properties: {
//     publisher: 'Microsoft.Azure.ActiveDirectory'
//     type: 'AADLoginForWindows'
//     typeHandlerVersion: '1.0'
//     autoUpgradeMinorVersion: true
//     settings: {}
//   }
// }

// resource logAnalyticsAgentExtension 'Microsoft.Compute/virtualMachines/extensions@2021-07-01' = {
//   name: 'Microsoft.Insights.LogAnalyticsAgent'
//   parent: windowsVM
//   location: location
//   properties: {
//     publisher: 'Microsoft.EnterpriseCloud.Monitoring'
//     type: 'MicrosoftMonitoringAgent'
//     typeHandlerVersion: '1.0'
//     autoUpgradeMinorVersion: true
//     settings: {
//       workspaceId: logAnalyticsWorkspace.id
//     }
//     protectedSettings: {
//       workspaceKey: logAnalyticsWorkspace.listKeys().primarySharedKey
//     }
//   }
// }

//TODO Add the Azure Diagnostics Extension from https://docs.microsoft.com/en-us/azure/azure-monitor/agents/resource-manager-agent#diagnostic-extension


