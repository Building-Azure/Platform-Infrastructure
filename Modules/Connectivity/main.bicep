resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: 'hub-westeurope'
  location: 'westeurope'
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
          addressPrefix: '10.100.0.0/24'
        }
      }
    ]
  }
}

resource publicIP 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: 'hub-westeurope-gateway-pip'
  location: 'westeurope'
  properties: {
    
  }
}


/* resource virtualNetworkGateway 'Microsoft.Network/virtualNetworkGateways@2020-11-01' = {
  name: 'hub-westeurope-gateway'
  location: 'westeurope'
  properties: {
    ipConfigurations: [
      {
        name: 'ipconf'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: 'virtualNetwork::GatewaySubnet.id'
          }
          publicIPAddress: {
            id: 'publicIP.id'
          }
        }
      }
    ]
    sku: {
      name: 'Basic'
      tier: 'Basic'
    }
    gatewayType: 'Vpn'
    vpnType: 'PolicyBased'
    enableBgp: true
  }
} */

