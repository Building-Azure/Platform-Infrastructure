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
    domainControllerName: 'dc01'
  }
  {
    region: 'northeurope'
    addressSpace: '10.101.0.0'
    hqPublicIPAddress: '185.116.112.220'
    hqLocalAddressPrefix: '192.168.1.0/24'
    domainControllerName: 'dc02'
  }
  {
    region: 'eastus'
    addressSpace: '10.102.0.0'
    hqPublicIPAddress: '185.116.112.220'
    hqLocalAddressPrefix: '192.168.1.0/24'
    domainControllerName: 'dc03'
  }
  {
    region: 'westus'
    addressSpace: '10.103.0.0'
    hqPublicIPAddress: '185.116.112.220'
    hqLocalAddressPrefix: '192.168.1.0/24'
    domainControllerName: 'dc04'
  }
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
    adminPassword:adminPassword
    domainControllerName: azureRegion.domainControllerName
  }
}]
