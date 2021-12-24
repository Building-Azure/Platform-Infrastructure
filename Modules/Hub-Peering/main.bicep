param identityVirtualNetworkName string
param identityVirtualNetworkResourceGroup string
param hubVirtualNetworkName string

resource identityVirtualNetwork 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: identityVirtualNetworkName
  scope: resourceGroup(identityVirtualNetworkResourceGroup)
}

resource hubVirtualNetwork 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: hubVirtualNetworkName
}

resource peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-05-01' = {
  name: '${hubVirtualNetwork.name}/identity'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: identityVirtualNetwork.id
    }
  }
}
