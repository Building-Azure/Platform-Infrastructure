var location = 'westeurope'
param adminUsername string
param adminPassword string
param workspaceKey string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: 'identity-spoke-virtualnetwork'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.100.1.0/24'
      ]
    }
    subnets: [
      {
        name: 'DomainControllerSubnet'
        properties: {
          addressPrefix: '10.100.1.0/28'
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
          privateIPAddress: '10.100.1.4'
        }
      }
    ]
  }
}

resource windowsVM 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: 'dc01-win2022'
  location: location
  properties: {
    licenseType: 'Windows_Server'

    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    osProfile: {
      computerName: 'DC01-WIN2022'
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
        name: 'dc01-osDisk'
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
  name: 'dc01-win2022/AzureNetworkWatcherExtension'
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
  name: 'dc01-win2022/IaaSAntimalware'
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
  name: 'dc01-win2022/AzureMonitorWindowsAgent'
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
  name: 'dc01-win2022/Microsoft.Insights.LogAnalyticsAgent'
  location: location
  properties: {
    publisher: 'Microsoft.EnterpriseCloud.Monitoring'
    type: 'MicrosoftMonitoringAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {
      workspaceId: 'fb0a7adb-8812-4cd9-b204-3faddd83b6bf'
    }
    protectedSettings: {
      workspaceKey: workspaceKey
    }
  }
}
