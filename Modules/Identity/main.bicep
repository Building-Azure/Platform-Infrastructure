var location = 'westeurope'
param adminUsername string
param adminPassword string

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

