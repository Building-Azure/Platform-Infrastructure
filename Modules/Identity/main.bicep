param location string

@secure()
param adminUsername string

@secure()
param adminPassword string

param domainControllerName string
param addressSpace string
param logAnalyticsWorkspaceName string
param logAnalyticsResourceGroup string
param hubVirtualNetworkName string
param hubVirtualNetworkResourceGroup string
param hqPrimaryDNSServerIP string
param hqSecondaryDNSServerIP string

@secure()
param domainJoinUsername string

@secure()
param domainJoinPassword string

param domainFQDN string

param orgUnitPath string

// param nsgFlowLogsStorageAccountName string
// param nsgFlowLogsStorageAccountResourceGroup string

// This should return an array of something like ['10', '100', '0', '0'] which makes it easier to use for subnetting below
var addressSpaceOctets = split(addressSpace, '.')

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: logAnalyticsWorkspaceName
  scope: resourceGroup(logAnalyticsResourceGroup)
}

resource hubVirtualNetwork 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: hubVirtualNetworkName
  scope: resourceGroup(hubVirtualNetworkResourceGroup)
}

// resource nsgFlowLogsStorageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' existing = {
//   name: nsgFlowLogsStorageAccountName
//   scope: resourceGroup(nsgFlowLogsStorageAccountResourceGroup)
// }

resource dcSubnetNetworkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: 'dc-subnet-nsg-${location}'
  location: location
  properties: {
    securityRules: []
  }
}

// resource networkWatcher 'Microsoft.Network/networkWatchers@2021-05-01' existing = {
//   name: location
//   scope: resourceGroup('platform-networkwatcher')
// }

// resource nsgFlowLog 'Microsoft.Network/networkWatchers/flowLogs@2021-05-01' = {
//   name: '${networkWatcher.name}/${dcSubnetNetworkSecurityGroup.name}'
//   location: location
  
//   properties: {
//     enabled: true
//     flowAnalyticsConfiguration: {
//       networkWatcherFlowAnalyticsConfiguration: {
//         enabled: true
//         trafficAnalyticsInterval: 60
//         workspaceResourceId: logAnalyticsWorkspace.id
//       }
//     }
//     format: {
//       type: 'JSON'
//       version: 2
//     }
//     retentionPolicy: {
//       days: 60
//       enabled: true
//     }
//     storageId: nsgFlowLogsStorageAccount.id
//     targetResourceId: dcSubnetNetworkSecurityGroup.id
//   }
// }

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: 'identity-virtualnetwork-${location}'
  location: location
  properties: {
    dhcpOptions: {
      dnsServers: [
        '${hqPrimaryDNSServerIP}'
        '${hqSecondaryDNSServerIP}'
      ]
    }
    addressSpace: {
      addressPrefixes: [
        '${addressSpaceOctets[0]}.${addressSpaceOctets[1]}.1.0/24' // Interpolating the first and second octet from the array
      ]
    }
    subnets: [
      {
        name: 'DomainControllerSubnet'
        properties: {
          addressPrefix: '${addressSpaceOctets[0]}.${addressSpaceOctets[1]}.1.0/28'
          networkSecurityGroup: {
            id: dcSubnetNetworkSecurityGroup.id
          }
        }
      }
    ]
  }
  //This creates a strongly typed reference so we can obtain the ID which is needed in the VNET Gateway resource
  resource domainControllerSubnet 'subnets' existing = {
    name: 'DomainControllerSubnet'
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
            id: virtualNetwork::domainControllerSubnet.id
          }
          privateIPAddress: '${addressSpaceOctets[0]}.${addressSpaceOctets[1]}.1.4'
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
      computerName: domainControllerName
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
        sku: '2022-datacenter-azure-edition'
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
  name: '${domainControllerName}/AzureNetworkWatcherExtension'
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
  name: '${domainControllerName}/IaaSAntimalware'
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

resource azureMonitorWindowsAgentExtension 'Microsoft.Compute/virtualMachines/extensions@2021-07-01' = {
  name: '${domainControllerName}/AzureMonitorWindowsAgent'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: 'AzureMonitorWindowsAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {}
  }
}

resource activeDirectoryDomainJoinExtension 'Microsoft.Compute/virtualMachines/extensions@2021-07-01' = {
  name: '${domainControllerName}/joindomain'
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

// resource AADLoginExtension 'Microsoft.Compute/virtualMachines/extensions@2021-07-01' = {
//   name: '${domainControllerName}/AADLogin'
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
//   name: '${domainControllerName}/Microsoft.Insights.LogAnalyticsAgent'
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

resource identitySpokePeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-05-01' = {
  name: '${virtualNetwork.name}/hub'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true
    useRemoteGateways: true
    remoteVirtualNetwork: {
      id: hubVirtualNetwork.id
    }
  }
}

output identityVirtualNetworkName string = virtualNetwork.name
