targetScope = 'subscription'

param companyPrefix string = 'platform'

// Enter the Azure Regions you wish to use. This will deploy things like a networking hub and active directory domain controller VM into each region. Certain resources like Log Analytics Workspace will be only deployed into a single region - selected from the first element of this array
param azureRegions array = [
  'westeurope'
  'northeurope'
] 

// resource connectivityRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
//   name: '${companyPrefix}-connectivity'
//   location: location
// }

// resource identityRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
//   name: '${companyPrefix}-identity'
//   location: location
// }

// resource managementRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
//   name: '${companyPrefix}-management'
//   location: location
// }

resource networkWatcherRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${companyPrefix}-networkwatcher'
  location: azureRegions[0]
 }

module networkWatcher 'Modules/NetworkWatcher/main.bicep' = [for azureRegion in azureRegions: {
  name: 'networkWatcherModule-${azureRegion}'
  scope: networkWatcherRG
  params: {
    location: azureRegion
  }
}]
