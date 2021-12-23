var location = 'westeurope'

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
          addressPrefix: '10.100.0.0/28'
        }
      }
    ]
  }
  //This creates a strongly typed reference so we can obtain the ID which is needed in the VNET Gateway resource
  resource domainControllerSubnet 'subnets' existing = {
    name: 'DomainControllerSubnet'
  }
}
