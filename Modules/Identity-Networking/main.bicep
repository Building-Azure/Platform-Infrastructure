param location string
param hqPrimaryDNSServerIP string
param hqSecondaryDNSServerIP string
param addressSpace string

// This should return an array of something like ['10', '100', '0', '0'] which makes it easier to use for subnetting below
var addressSpaceOctets = split(addressSpace, '.')

resource dcSubnetNetworkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: 'dc-subnet-nsg-${location}'
  location: location
  properties: {
    securityRules: []
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: 'identity-virtualnetwork-${location}'
  location: location
  properties: {
    dhcpOptions: {
      dnsServers: [
        '${hqPrimaryDNSServerIP}'
        '${hqSecondaryDNSServerIP}'
        // '168.63.129.16' //Azure Provided DNS - without this, Log Analytics won't get data from Agents
      ]
    }
    addressSpace: {
      addressPrefixes: [
        '${addressSpaceOctets[0]}.${addressSpaceOctets[1]}.4.0/22' // Interpolating the first and second octet from the array
      ]
    }
    subnets: [
      {
        name: 'DomainControllerSubnet'
        properties: {
          addressPrefix: '${addressSpaceOctets[0]}.${addressSpaceOctets[1]}.4.0/28'
          networkSecurityGroup: {
            id: dcSubnetNetworkSecurityGroup.id
          }
        }
      }
    ]
  }
  //This creates a strongly typed reference so we can obtain the ID which is needed in the VNET Gateway resource
  resource domainControllerSubnet 'subnets' existing = {
    name: 'DomainControllerSubnet'
  }
}

output identityVirtualNetworkId string = virtualNetwork.id
output identityVirtualNetworkName string = virtualNetwork.name
output domainControllerSubnetId string = virtualNetwork::domainControllerSubnet.id
