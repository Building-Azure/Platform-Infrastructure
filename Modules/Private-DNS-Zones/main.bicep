param azureRegions array
param dnsZoneName string


resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-05-01' existing = [for (azureRegion, i) in azureRegions: {
  //TODO - Remove this hardcoding
  name: 'identity-virtualnetwork-${azureRegion.region}'
  scope: resourceGroup('platform-identity-${azureRegion.region}')
}]

// What I need to do here is 1) Create a zone for each supported Private Endpoint Resource 2) Create a VNET link for each region I have in Azure and link to appropriate identity vnete 
resource privateDNSZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: dnsZoneName
  location: 'global'
  
  //There should be a vnet link for each azure region
  resource vnetLink 'virtualNetworkLinks@2020-06-01' = [for (azureRegion, i) in azureRegions: {
    name: 'identity-${azureRegion.region}'
    location: 'global'
    properties: {
      registrationEnabled: false
      virtualNetwork: {
        id: virtualNetwork[i].id
      }
    }
  }]
}

