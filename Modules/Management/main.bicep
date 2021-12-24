var location = 'westeurope'

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
  name: 'platformazurecshell'
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Premium_LRS'
  }
  tags: {
    'usage' : 'Azure Cloud Shell'
  }
}


