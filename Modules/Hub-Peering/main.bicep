param identityVirtualNetworkName string
param identityVirtualNetworkResourceGroup string

resource identityVirtualNetwork 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: identityVirtualNetworkName
  scope: resourceGroup(identityVirtualNetworkResourceGroup)
}

resource peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-07-01' = {
  name: '${identityVirtualNetworkName}/identity'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: '${identityVirtualNetwork.id}'
    }
  }
}
