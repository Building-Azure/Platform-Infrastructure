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
  //This creates a strongly typed reference so we can obtain the ID which is needed in the VNET Gateway resource
  resource gatewaySubnet 'subnets' existing = {
    name: 'GatewaySubnet'
  }
}

resource publicIP 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: 'hub-westeurope-gateway-pip'
  location: 'westeurope'
  sku: {
    name: 'Standard'
  }
  zones: [
    '1'
    '2'
    '3'
  ]
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: 'buildingazure-gateway'
    }
  }
}

resource localNetworkGateway 'Microsoft.Network/localNetworkGateways@2021-05-01' = {
  name: 'buildingazure-hq-lgw'
  location: 'westeurope'
  properties: {
    fqdn: 'buildingazure-gateway.westeurope.cloudapp.azure.com'
    localNetworkAddressSpace: {
      addressPrefixes: [
        '192.168.1.0/24'
      ]
    }
  }
}

resource virtualNetworkGateway 'Microsoft.Network/virtualNetworkGateways@2020-11-01' = {
  name: 'hub-westeurope-gateway'
  location: 'westeurope'
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
    vpnType: 'PolicyBased'
    enableBgp: true
  }
}

output subnetResourceId string = virtualNetwork::gatewaySubnet.id
