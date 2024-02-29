param azurefwName string
param location string
param firewallPolicyID string
param subnetid string
param skuname string
param skutier string
param threatIntelMode string = ''
param zones array = []

resource fwpip 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: '${azurefwName}-pip'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    deleteOption: 'Delete'
  }
}

resource AzureFirewall 'Microsoft.Network/azureFirewalls@2023-04-01' = {
  name: azurefwName
  location: location
  properties: {
    additionalProperties: {}
    firewallPolicy: {
      id: firewallPolicyID
    }
    ipConfigurations:[
      {
        name: fwpip.name
        id:fwpip.id
        properties: {
          publicIPAddress: {
            id: fwpip.id
          }
          subnet: {
            id: subnetid
          }
        }
      }
    ] 
    sku: {
      name: skuname
      tier: skutier
    }
    threatIntelMode: threatIntelMode != '' ? '' : threatIntelMode
  }
  zones: zones != [] ? [] : zones
}

output azureFirewallprivateIP string = AzureFirewall.properties.ipConfigurations[0].properties.privateIPAddress
