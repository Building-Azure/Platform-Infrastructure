param location string

var dnsZones = [
  'privatelink.azure-automation.net'
  'privatelink.database.windows.net'
] 
// What I need to do here is 1) Create a zone for each supported Private Endpoint Resource 2) Create a VNET link for each region I have in Azure and link to appropriate identity vnete 
resource privateDNSZone 'Microsoft.Network/privateDnsZones@2018-09-01' = [for dnsZone in dnsZones: {
  name: dnsZone
  location: location
}]

