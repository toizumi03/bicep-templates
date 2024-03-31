param locationSite1 string
param vmAdminUsername string
@secure()
param vmAdminPassword string

/* ****************************** consumet-Vnet ****************************** */

module defaultNSGSite1 '../modules/nsg.bicep' = {
  name: 'NetworkSecurityGroupSite1'
  params:{
    location: locationSite1
    name: 'nsg-site1'  
  }
}
resource consumer_vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: 'consumer-vnet'
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
    ]
  }
}

var stinternallbName = 'public-LB'
module publicLB '../modules/standard_public_lb.bicep' = {
  name: stinternallbName
  params: {
    loadbalancerName: stinternallbName
    location: locationSite1
    loadbalancingRules_protocol : 'tcp'
    loadbalancingRules_frontendPort: 80
    loadbalancingRules_backendPort: 80
    loadbalancingRules_idleTimeoutInMinutes: 5
    probes_protocol: 'tcp'
    probes_port: 80
    probes_intervalInSeconds: 5
    gatewayLoadBalancerfrontendipid: gatewaylb.outputs.GwloadBalancerFrontEndId
  }
  dependsOn: [
    gatewaylb
  ]
}

module clientvm '../modules/ubuntu20.04.bicep' = {
  name: 'client-vm'
  params: {
    vmName: 'clientvm'
    VMadminUsername: vmAdminUsername
    VMadminpassword: vmAdminPassword
    location: locationSite1
    subnetId: consumer_vnet.properties.subnets[0].id
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
    subnetId: consumer_vnet.properties.subnets[0].id
    loadBalancerBackendAddressPoolsId: publicLB.outputs.loadBalancerbackendAddressPools_id
    usePublicIP: true
    customData: loadFileAsBase64('cloud-init.yml')
  }
}]

/* ****************************** Provider-Vnet ****************************** */

resource provider_vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: 'provider-vnet'
  location: locationSite1
  properties: {
    addressSpace: {
      addressPrefixes: [
        '192.168.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '192.168.0.0/24'
          networkSecurityGroup: { id: defaultNSGSite1.outputs.nsgId }
        }
      }
    ]
  }
}

module gatewaylb '../modules/gateway_lb.bicep' = {
  name: 'gateway-lb'
  params: {
    gwlbName: 'gateway-lb'
    location: locationSite1
    gwlbFrontEndName: 'gwlbFrontEnd'
    gwlbFrontEndIP: '192.168.0.7'
    gwlbBackEndPoolName: 'gwlbBackEndPool'
    vxlanTunnelInternalPort: 10800
    vxlanTunnelInternalIdentifier: 800
    vxlanTunnelExternalPort: 10801
    vxlanTunnelExternalIdentifier: 801
    gwlbProbeName: 'gwlbProbe'
    gwlbprobePort: 8080
  }
  dependsOn: [
    provider_vnet
  ]
}

module NVA '../modules/ubuntu20.04.bicep' = {
  name: 'NVA-VM'
  params: {
    vmName: 'NVA-VM'
    VMadminUsername: vmAdminUsername
    VMadminpassword: vmAdminPassword
    location: locationSite1
    subnetId: provider_vnet.properties.subnets[0].id
    usePublicIP: true
    loadBalancerBackendAddressPoolsId: gatewaylb.outputs.GwloadBalancerbackendAddressPoolId
    enableIPForwarding: true
    customData: loadFileAsBase64('nvaconfig.yml')
  }
}
