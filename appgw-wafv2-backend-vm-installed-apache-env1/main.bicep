param locationSite1 string
param vmAdminUsername string
@secure()
param vmAdminPassword string
param enablediagnostics bool

/* ****************************** Cloud-Vnet ****************************** */

module defaultNSGSite1 '../modules/nsg.bicep' = {
  name: 'NetworkSecurityGroupSite1'
  params:{
    location: locationSite1
    name: 'nsg-site1'  
  }
}
resource cloud_vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: 'cloud-vnet'
  location: locationSite1
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: { id: defaultNSGSite1.outputs.nsgId }
        }
      }
      {
        name: 'appgwsubnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
      {
        name: 'backendsubnet'
        properties: {
          addressPrefix: '10.0.2.0/24'
        }
      }
    ]
  }
}

resource AppGWPIP 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: 'PublicIP'
  location: locationSite1
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
  }
}

module applicationGateway 'br/public:avm/res/network/application-gateway:0.6.0' = {
  name: 'ApplicationGateway'
  params: {
    // Required parameters
    name: 'ApplicationGateway'
    // Non-required parameters
    backendAddressPools: [
      {
        name: 'backendAddressPool1'
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'backendHttpSettings1'
        properties: {
          cookieBasedAffinity: 'Disabled'
          port: 80
          protocol: 'Http'
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'frontendIPConfig1'
        properties: {
          publicIPAddress: {
            id: AppGWPIP.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'frontendPort1'
        properties: {
          port: 80
        }
      }
    ]
    gatewayIPConfigurations: [
      {
        name: 'publicIPConfig1'
        properties: {
          subnet: {
            id: cloud_vnet.properties.subnets[1].id
          }
        }
      }
    ]
    httpListeners: [
      {
        name: 'httpListener1'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', 'ApplicationGateway', 'frontendIPConfig1')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', 'ApplicationGateway', 'frontendPort1')
          protocol: 'Http'
        }
      }
    }
    ]
    location: locationSite1
    requestRoutingRules: [
      {
        name: 'requestRoutingRule1'
        properties: {
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', 'ApplicationGateway', 'backendAddressPool1')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', 'ApplicationGateway', 'backendHttpSettings1')
          }
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', 'ApplicationGateway', 'httpListener1')
          }
          priority: 100
          ruleType: 'Basic'
        }
      }
    ]
    sku: 'Standard_v2'
  }
}


module clientvm_ubuntu '../modules/ubuntu20.04.bicep' = {
  name: 'client-ubuntu-vm'
  params: {
    vmName: 'client-ubuntu-vm'
    VMadminUsername: vmAdminUsername
    VMadminpassword: vmAdminPassword
    location: locationSite1
    subnetId: cloud_vnet.properties.subnets[0].id
    usePublicIP: true
  }
}

var numberOfInstances = 2
module backendvms '../modules/ubuntu20.04.bicep' = [for i in range(0, numberOfInstances):{
  name: 'backend-vm${i}'
  params: {
    vmName: 'backendvm${i}'
    VMadminUsername: vmAdminUsername
    VMadminpassword: vmAdminPassword
    location: locationSite1
    subnetId: cloud_vnet.properties.subnets[2].id
    customData: loadFileAsBase64('apache.yml')
    applicationGatewayBackendAddressPoolsId: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', 'ApplicationGateway', 'backendAddressPool1')
  }
  dependsOn: [
    applicationGateway
  ]
}]

