param remoteVirtualNetworkID string
param remotePeerName string
param useRemoteGateways bool
param localVirtualNetworkName string


param allowVirtualNetworkAccess bool = true
param allowForwardedTraffic bool = true
param allowGatewayTransit bool = true


resource localVirtualNetwork 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: localVirtualNetworkName
}

resource peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-05-01' = {
  name: '${localVirtualNetwork.name}/${remotePeerName}'
  properties: {
    allowVirtualNetworkAccess: allowVirtualNetworkAccess
    allowForwardedTraffic: allowForwardedTraffic
    allowGatewayTransit: allowGatewayTransit
    useRemoteGateways: useRemoteGateways
    remoteVirtualNetwork: {
      id: remoteVirtualNetworkID
    }
  }
}
