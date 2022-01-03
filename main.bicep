targetScope = 'subscription'

param companyPrefix string = 'platform'
param preSharedKey string
param adminUsername string
param adminPassword string

// Enter the Azure Regions you wish to use. This will deploy things like a networking hub and active directory domain controller VM into each region. Certain resources like Log Analytics Workspace will be only deployed into a single region - selected from the first element of this array
param azureRegions array = [
  {
    //Primary Azure Region for global resources like Log Analytics Workspace
    region: 'westeurope'
    addressSpace: '10.100.0.0'
    hqPublicIPAddress: '185.116.112.220'
    hqLocalAddressPrefix: '192.168.1.0/24'
    domainControllerName: 'dc03'
  }
  {
    region: 'northeurope'
    addressSpace: '10.101.0.0'
    hqPublicIPAddress: '185.116.112.220'
    hqLocalAddressPrefix: '192.168.1.0/24'
    domainControllerName: 'dc04'
  }
  {
    region: 'eastus'
    addressSpace: '10.102.0.0'
    hqPublicIPAddress: '185.116.112.220'
    hqLocalAddressPrefix: '192.168.1.0/24'
    domainControllerName: 'dc05'
  }
  {
    region: 'westus'
    addressSpace: '10.103.0.0'
    hqPublicIPAddress: '185.116.112.220'
    hqLocalAddressPrefix: '192.168.1.0/24'
    domainControllerName: 'dc06'
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
 resource connectivityRG 'Microsoft.Resources/resourceGroups@2021-04-01' = [for azureRegion in azureRegions: {
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

resource networkWatcherRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${companyPrefix}-networkwatcher'
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
  }
}

module networkWatcher 'Modules/NetworkWatcher/main.bicep' = [for azureRegion in azureRegions: {
  name: 'networkWatcherModule-${azureRegion.region}'
  scope: networkWatcherRG
  params: {
    location: azureRegion.region
  }
}]

module connectivityModule 'Modules/Connectivity/main.bicep' = [for (azureRegion, i) in azureRegions: {
  name: 'connectivityModule-${azureRegion.region}'
  scope: connectivityRG[i]
  params: {
    location: azureRegion.region
    addressSpace: azureRegion.addressSpace
    hqPublicIPAddress: azureRegion.hqPublicIPAddress
    hqLocalAddressPrefix: azureRegion.hqLocalAddressPrefix
    preSharedKey: preSharedKey
  }
}]

module identityModule 'Modules/Identity/main.bicep' = [for (azureRegion, i) in azureRegions: {
  name: 'identityModule-${azureRegion.region}'
  scope: identityRG[i]
  params: {
    location: azureRegion.region
    addressSpace: azureRegion.addressSpace
    adminUsername: adminUsername
    adminPassword: adminPassword
    domainControllerName: azureRegion.domainControllerName
    logAnalyticsWorkspaceName: managementModule.outputs.logAnalyticsWorkspaceName
    logAnalyticsResourceGroup: managementRG.name
    hubVirtualNetworkName: connectivityModule[i].outputs.hubVirtualNetworkName
    hubVirtualNetworkResourceGroup: connectivityRG[i].name
    nsgFlowLogsStorageAccountName: networkWatcher[i].outputs.nsgFlowLogsStorageAccountName
    nsgFlowLogsStorageAccountResourceGroup: networkWatcherRG.name
  }
}]

module hubPeeringModule 'Modules/Hub-Peering/main.bicep' = [for (azureRegion, i) in azureRegions: {
  name: 'hubPeeringModule-${azureRegion.region}'
  scope: connectivityRG[i]
  params: {
    identityVirtualNetworkName: identityModule[i].outputs.identityVirtualNetworkName
    identityVirtualNetworkResourceGroup: identityRG[i].name
    hubVirtualNetworkName: connectivityModule[i].outputs.hubVirtualNetworkName
  }
}]

module dnsZoneModule 'Modules/Private-DNS-Zones/main.bicep' = [for (dnsZone, i) in dnsZones: {
  name: 'privateDNSZoneModule-${dnsZone}'
  scope: privateDNSZoneRG
  params: {
    azureRegions : azureRegions
    dnsZoneName: dnsZone
  }
}]

