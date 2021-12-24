param location string

// To keep it simple each location has it's own network watcher in each subscription per region.
resource networkWatcher 'Microsoft.Network/networkWatchers@2021-05-01' = {
  name: location
  location: location
}
