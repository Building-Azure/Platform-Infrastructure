var location = 'westeurope' 

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: 'hub-virtualnetwork'
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

resource publicIP 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: 'hub-gateway-pip'
  location: location
  sku: {
    name: 'Standard'
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
    fqdn: 'buildingazure-gateway.westeurope.cloudapp.azure.com'
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

output subnetResourceId string = virtualNetwork::gatewaySubnet.id
