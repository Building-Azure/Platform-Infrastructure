param location string

// To keep it simple each location has it's own network watcher in each subscription per region.
resource networkWatcher 'Microsoft.Network/networkWatchers@2021-05-01' = {
  name: location
  location: location
}

resource nsgFlowLogsStorageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: '${location}${uniqueString(resourceGroup().id)}'
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_GRS'
  }
  tags: {
    'usage' : 'NSG Flow Logs'
  }
}

output nsgFlowLogsStorageAccountName string = nsgFlowLogsStorageAccount.name
