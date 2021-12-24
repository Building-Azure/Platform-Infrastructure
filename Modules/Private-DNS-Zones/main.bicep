param location string
param privateDNSZoneName string
// What I need to do here is 1) Create a zone for each supported Private Endpoint Resource 2) Create a VNET link for each region I have in Azure and link to appropriate identity vnete 
resource privateDNSZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDNSZoneName
  location: location
}

