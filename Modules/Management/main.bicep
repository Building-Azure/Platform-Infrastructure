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

resource storageaccount 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: 'cshellstg${uniqueString(resourceGroup().id)}'
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Premium_LRS'
  }
  tags: {
    'usage' : 'Azure Cloud Shell'
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
