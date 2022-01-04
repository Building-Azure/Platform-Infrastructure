targetScope = 'subscription'

param companyPrefix string = 'platform'

@secure()
param preSharedKey string

@secure()
param adminUsername string

@secure()
param adminPassword string

@secure()
param domainJoinUsername string

@secure()
param domainJoinPassword string

param domainFQDN string = 'buildingazure.co.uk'

param orgUnitPath string = 'OU=AZURE,DC=BUILDINGAZURE,DC=CO,DC=UK'

param hqPrimaryDNSServerIP string = '192.168.1.40'
param hqSecondaryDNSServerIP string = '192.168.1.41'

param hqPublicIPAddress string = '185.116.112.220'
param hqLocalAddressPrefix string = '192.168.1.0/24'

// Enter the Azure Regions you wish to use. This will deploy things like a networking hub and active directory domain controller VM into each region. Certain resources like Log Analytics Workspace will be only deployed into a single region - selected from the first element of this array
param azureRegions array = [
  {
    //Primary Azure Region for global resources like Log Analytics Workspace
    region: 'westeurope'
    addressSpace: '10.100.0.0'  // This infers that each region gets a /16 mask - 65534 usable IP addresses - do not overlap this with another region if you intend to peer the vnets later.
    domainControllerName: 'dc03'
  }
  {
    region: 'northeurope'
    addressSpace: '10.101.0.0'
    domainControllerName: 'dc04'
  }
]

param dnsZones array = [
  'privatelink.azure-automation.net'
  #disable-next-line no-hardcoded-env-urls
  'privatelink.database.windows.net'
  'privatelink.sql.azuresynapse.net'
  'privatelink.dev.azuresynapse.net'
  'privatelink.azuresynapse.net'
  #disable-next-line no-hardcoded-env-urls
  'privatelink.blob.core.windows.net'
  #disable-next-line no-hardcoded-env-urls
  'privatelink.table.core.windows.net'
  #disable-next-line no-hardcoded-env-urls
  'privatelink.queue.core.windows.net'
  #disable-next-line no-hardcoded-env-urls
  'privatelink.file.core.windows.net'
  #disable-next-line no-hardcoded-env-urls
  'privatelink.web.core.windows.net'
  #disable-next-line no-hardcoded-env-urls
  'privatelink.dfs.core.windows.net'
  'privatelink.documents.azure.com'
  'privatelink.mongo.cosmos.azure.com'
  'privatelink.cassandra.cosmos.azure.com'
  'privatelink.gremlin.cosmos.azure.com'
  'privatelink.table.cosmos.azure.com'
  'privatelink.postgres.database.azure.com'
  'privatelink.mysql.database.azure.com'
  'privatelink.mariadb.database.azure.com'
  'privatelink.vaultcore.azure.net'
  'privatelink.search.windows.net'
  'privatelink.azurecr.io'
  'privatelink.azconfig.io'
  'privatelink.siterecovery.windowsazure.com'
  'privatelink.servicebus.windows.net'
  'privatelink.azure-devices.net'
  'privatelink.eventgrid.azure.net'
  'privatelink.azurewebsites.net'
  'privatelink.api.azureml.ms'
  'privatelink.notebooks.azure.net'
  'privatelink.service.signalr.net'
  'privatelink.monitor.azure.com'
  'privatelink.oms.opinsights.azure.com'
  'privatelink.ods.opinsights.azure.com'
  'privatelink.agentsvc.azure-automation.net'
  'privatelink.cognitiveservices.azure.com'
  'privatelink.afs.azure.net'
  'privatelink.datafactory.azure.net'
  'privatelink.adf.azure.com'
  'privatelink.redis.cache.windows.net'
  'privatelink.redisenterprise.cache.azure.net'
  'privatelink.purview.azure.com'
  'privatelink.purviewstudio.azure.com'
  'privatelink.digitaltwins.azure.net'
  'privatelink.azurehdinsight.net'
]
resource hubNetworkingRG 'Microsoft.Resources/resourceGroups@2021-04-01' = [for azureRegion in azureRegions: {
  name: '${companyPrefix}-connectivity-${azureRegion.region}'
  location: azureRegion.region
}]

resource identityRG 'Microsoft.Resources/resourceGroups@2021-04-01' = [for azureRegion in azureRegions: {
  name: '${companyPrefix}-identity-${azureRegion.region}'
  location: azureRegion.region
}]

resource managementRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${companyPrefix}-management'
  location: azureRegions[0].region
}

resource privateDNSZoneRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${companyPrefix}-privatednszones'
  location: azureRegions[0].region
}

module managementModule 'Modules/Management/main.bicep' = {
  name: 'managementModule'
  scope: managementRG
  params: {
    location: azureRegions[0].region
    domainJoinUsername: domainJoinUsername
    domainJoinPassword: domainJoinPassword
  }
}

module networkWatcher 'Modules/NetworkWatcher/main.bicep' = [for azureRegion in azureRegions: {
  name: 'networkWatcherModule-${azureRegion.region}'
  scope: resourceGroup('NetworkWatcherRG')
  params: {
    location: azureRegion.region
  }
}]

module hubNetworkingModule 'Modules/Hub-Networking/main.bicep' = [for (azureRegion, i) in azureRegions: {
  name: 'hubNetworkingModule-${azureRegion.region}'
  scope: hubNetworkingRG[i]
  params: {
    location: azureRegion.region
    addressSpace: azureRegion.addressSpace
    hqPublicIPAddress: hqPublicIPAddress
    hqLocalAddressPrefix: hqLocalAddressPrefix
    preSharedKey: preSharedKey
  }
}]

module identityNetworkingModule 'Modules/Identity-Networking/main.bicep' = [for (azureRegion, i) in azureRegions: {
  name: 'identityNetworkingModule-${azureRegion.region}'
  scope: identityRG[i]
  params: {
    location: azureRegion.region
    addressSpace: azureRegion.addressSpace
    hqPrimaryDNSServerIP: hqPrimaryDNSServerIP
    hqSecondaryDNSServerIP: hqSecondaryDNSServerIP
  }
}]

module hubToSpokePeeringModule 'Modules/VirtualNetwork-Peering/main.bicep' = [for (azureRegion, i) in azureRegions: {
  name: 'hubToSpokePeeringModule-${azureRegion.region}'
  scope: hubNetworkingRG[i]
  params: {
    useRemoteGateways: false
    remoteVirtualNetworkID: identityNetworkingModule[i].outputs.identityVirtualNetworkId
    remotePeerName: 'Identity'
    localVirtualNetworkName: hubNetworkingModule[i].outputs.hubVirtualNetworkName
  }
}]

module spokeToHubPeeringModule 'Modules/VirtualNetwork-Peering/main.bicep' = [for (azureRegion, i) in azureRegions: {
  name: 'spokeToHubPeeringModule-${azureRegion.region}'
  scope: identityRG[i]
  params: {
    useRemoteGateways: true
    remoteVirtualNetworkID: hubNetworkingModule[i].outputs.hubVirtualNetworkId
    remotePeerName: 'Hub'
    localVirtualNetworkName: identityNetworkingModule[i].outputs.identityVirtualNetworkName
  }
}]

module identityModule 'Modules/Identity-DomainControllers/main.bicep' = [for (azureRegion, i) in azureRegions: {
  name: 'identityDomainControllerModule-${azureRegion.region}'
  scope: identityRG[i]
  dependsOn: [
    spokeToHubPeeringModule
    hubToSpokePeeringModule
  ]
  params: {
    location: azureRegion.region
    addressSpace: azureRegion.addressSpace
    adminUsername: adminUsername
    adminPassword: adminPassword
    domainControllerName: azureRegion.domainControllerName
    logAnalyticsWorkspaceName: managementModule.outputs.logAnalyticsWorkspaceName
    logAnalyticsResourceGroup: managementRG.name
    domainFQDN: domainFQDN
    domainJoinPassword: domainJoinPassword
    domainJoinUsername: domainJoinUsername
    orgUnitPath: orgUnitPath
    domainControllerSubnetId: identityNetworkingModule[i].outputs.domainControllerSubnetId
  }
}]

module dnsZoneModule 'Modules/Private-DNS-Zones/main.bicep' = [for (dnsZone, i) in dnsZones: {
  name: 'privateDNSZoneModule-${dnsZone}'
  scope: privateDNSZoneRG
  
  //TODO: I should remove this explicit dependency once I sort out the hardcoding inside the dnsZoneModule for Identity
  dependsOn: [
    identityNetworkingModule
  ]
  params: {
    azureRegions: azureRegions
    dnsZoneName: dnsZone
  }
}]
