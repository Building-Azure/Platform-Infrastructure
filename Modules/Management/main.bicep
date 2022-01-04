param location string = 'westeurope'

@secure()
param domainJoinUsername string

@secure()
param domainJoinPassword string

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: 'platform-law'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

resource automationAccount 'Microsoft.Automation/automationAccounts@2021-06-22' = {
  name: 'platform-aa'
  location: location
  properties: {
    sku: {
      name: 'Free'
    }
  }
}

resource linkedService 'Microsoft.OperationalInsights/workspaces/linkedServices@2020-08-01' = {
  name: '${logAnalyticsWorkspace.name}/Automation'
  properties: {
    resourceId: automationAccount.id
  }
}

resource updateManagementSolution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: 'Updates(${logAnalyticsWorkspace.name})'
  location: location
  properties: {
    workspaceResourceId: logAnalyticsWorkspace.id
  }
  plan: {
    name: 'Updates(${logAnalyticsWorkspace.name})'
    publisher: 'Microsoft'
    product: 'OMSGallery/Updates'
    promotionCode: ''
  }
}

// This needs to be manually deleted whenever there is a change so I am commenting out
// resource changeTrackingSolution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
//   name: 'ChangeTracking(${logAnalyticsWorkspace.name})'
//   location: location
//   properties: {
//     workspaceResourceId: logAnalyticsWorkspace.id
//   }
//   plan: {
//     name: 'Updates(${logAnalyticsWorkspace.name})'
//     publisher: 'Microsoft'
//     product: 'OMSGallery/ChangeTracking'
//     promotionCode: ''
//   }
// }

resource VMInsightsSolution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: 'VMInsights(${logAnalyticsWorkspace.name})'
  location: location
  properties: {
    workspaceResourceId: logAnalyticsWorkspace.id
  }
  plan: {
    name: 'VMInsights(${logAnalyticsWorkspace.name})'
    publisher: 'Microsoft'
    product: 'OMSGallery/VMInsights'
    promotionCode: ''
  }
}

resource storageaccount 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: 'cshellstg${uniqueString(resourceGroup().id)}'
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Premium_LRS'
  }
  tags: {
    'usage': 'Azure Cloud Shell'
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  name: 'bldazureplatform'
  location: location
  properties: {
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: true
    enableRbacAuthorization: true
    enablePurgeProtection: false
    enableSoftDelete: false
    tenantId: tenant().tenantId
    accessPolicies: []
    sku: {
      name: 'standard'
      family: 'A'
    }
  }
}

resource keyVaultSecretDomainJoinUsername 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  parent: keyVault
  name: 'domainJoinUsername'
  properties: {
    value: domainJoinUsername
  }
}

resource keyVaultSecretDomainJoinPassword 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  parent: keyVault
  name: 'domainJoinPassword'
  properties: {
    value: domainJoinPassword
  }
}

output logAnalyticsWorkspaceName string = logAnalyticsWorkspace.name
