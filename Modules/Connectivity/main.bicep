param preSharedKey string
param location string 

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: 'hub-virtualnetwork-${location}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.100.0.0/24'
      ]
    }
    subnets: [
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '10.100.0.0/27'
        }
      }
    ]
  }
  //This creates a strongly typed reference so we can obtain the ID which is needed in the VNET Gateway resource
  resource gatewaySubnet 'subnets' existing = {
    name: 'GatewaySubnet'
  }
}

/* resource publicIP 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: 'hub-gateway-pip'
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: 'buildingazure-gateway'
    }
  }
}

resource localNetworkGateway 'Microsoft.Network/localNetworkGateways@2021-05-01' = {
  name: 'buildingazure-hq-lgw'
  location: location
  properties: {
    gatewayIpAddress: '185.116.112.220'
    localNetworkAddressSpace: {
      addressPrefixes: [
        '192.168.1.0/24'
      ]
    }
  }
}

resource virtualNetworkGateway 'Microsoft.Network/virtualNetworkGateways@2020-11-01' = {
  name: 'hub-gateway'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'gatewayIPConfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: virtualNetwork::gatewaySubnet.id
          }
          publicIPAddress: {
            id: publicIP.id
          }
        }
      }
    ]
    sku: {
      name: 'Basic'
      tier: 'Basic'
    }
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    enableBgp: false
  }
}

resource vpnVnetConnection 'Microsoft.Network/connections@2021-05-01' = {
  name: 'buildingazure-hq-connection'
  location: location
  properties: {
    virtualNetworkGateway1: {
      id: virtualNetworkGateway.id
      properties:{}
    }
    localNetworkGateway2: {
      id: localNetworkGateway.id
      properties:{}
    }
    connectionType: 'IPsec'
    routingWeight: 0
    sharedKey: preSharedKey
  }
}

resource peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-07-01' = {
  name: 'hub-virtualnetwork/identity'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: '/subscriptions/a8d89de8-d014-4deb-81f8-cecb19fbe41d/resourceGroups/bldazure-identity-westeurope/providers/Microsoft.Network/virtualNetworks/identity-spoke-virtualnetwork'
    }
  }
}

resource vpnStorageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: 'hubvpntroubleshooting'
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Premium_LRS'
  }
}

resource nsgFlowLogsStorageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: 'platformnsgflowlogs'
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Premium_LRS'
  }
  tags: {
    'usage' : 'NSG Flow Logs'
  }
}


output subnetResourceId string = virtualNetwork::gatewaySubnet.id */
