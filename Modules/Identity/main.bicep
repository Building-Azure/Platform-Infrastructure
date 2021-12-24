param location string
param adminUsername string
param adminPassword string
param domainControllerName string
// param workspaceKey string
param addressSpace string
param logAnalyticsWorkspaceName string
param logAnalyticsResourceGroup string 

// This should return an array of something like ['10', '100', '0', '0'] which makes it easier to use for subnetting below
var addressSpaceOctets = split(addressSpace, '.')

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: logAnalyticsWorkspaceName
  scope: resourceGroup(logAnalyticsResourceGroup)
}


resource dcSubnetNetworkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: 'dc-subnet-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'allowAll'
        properties: {
          description: 'description'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: 'identity-virtualnetwork-${location}'
  location: location
  properties: {
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
  name: 'dc01-nic'
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
  name: '${domainControllerName}-win2022'
  location: location
  properties: {
    licenseType: 'Windows_Server'

    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    osProfile: {
      computerName: '${toUpper(domainControllerName)}-WIN2022'
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
  name: '${domainControllerName}-win2022/AzureNetworkWatcherExtension'
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
  name: '${domainControllerName}-win2022/IaaSAntimalware'
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
  name: '${domainControllerName}-win2022/AzureMonitorWindowsAgent'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: 'AzureMonitorWindowsAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {}
  }
}

resource logAnalyticsAgentExtension 'Microsoft.Compute/virtualMachines/extensions@2021-07-01' = {
  name: '${domainControllerName}-win2022/Microsoft.Insights.LogAnalyticsAgent'
  location: location
  properties: {
    publisher: 'Microsoft.EnterpriseCloud.Monitoring'
    type: 'MicrosoftMonitoringAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {
      workspaceId: logAnalyticsWorkspace.id
    }
    protectedSettings: {
      workspaceKey: logAnalyticsWorkspace.listKeys().primarySharedKey
    }
  }
}

// resource peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-05-01' = {
//   name: 'identity-spoke-virtualnetwork/hub'
//   properties: {
//     allowVirtualNetworkAccess: true
//     allowForwardedTraffic: true
//     allowGatewayTransit: true
//     useRemoteGateways: true
//     remoteVirtualNetwork: {
//       id: '/subscriptions/a8d89de8-d014-4deb-81f8-cecb19fbe41d/resourceGroups/bldazure-connectivity-westeurope/providers/Microsoft.Network/virtualNetworks/hub-virtualnetwork'
//     }
//   }
// }


