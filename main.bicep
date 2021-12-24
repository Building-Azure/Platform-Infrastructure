targetScope = 'subscription'

param companyPrefix string = 'platform'
param location string = 'westeurope' 

resource connectivityRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${companyPrefix}-connectivity'
  location: location
}

resource identityRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${companyPrefix}-identity'
  location: location
}

resource managementRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${companyPrefix}-management'
  location: location
}

resource networkWatcherRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${companyPrefix}-networkwatcher'
  location: location
}
