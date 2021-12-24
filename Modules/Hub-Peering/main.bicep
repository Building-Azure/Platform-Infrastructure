param identityVirtualNetworkName string
param identityVirtualNetworkResourceGroup string
param hubVirtualNetworkName string
param hubVirtualNetworkResourceGroup string

resource identityVirtualNetwork 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: identityVirtualNetworkName
  scope: resourceGroup(identityVirtualNetworkResourceGroup)
}

resource hubVirtualNetwork 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: hubVirtualNetworkName
  scope: resourceGroup(hubVirtualNetworkResourceGroup)
}

resource peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-07-01' = {
  name: '${hubVirtualNetworkName}/identity'
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
