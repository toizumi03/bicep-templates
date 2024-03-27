@description('Username for the Virtual Machine.')
param vmAdminUsername string
@description('Password for the Virtual Machine.')
@secure()
param vmAdminPassword string
@description('All resources will be deployed to this location.')
param locationSite1 string
param enablediagnostics bool

/* ****************************** Cloud-Vnet ****************************** */

module frontdoor '../modules/cdn_profiles.bicep' = {
  name: 'azurefrontdoor'
  params:{
    afdName: 'frontdoor'
    afdlocation: 'Global'
    location: locationSite1
    sku: 'Premium_AzureFrontDoor'
    afdEndpointName: 'afdEndpoint'
    enabledState: 'Enabled'
    originGroupName: 'originGroup'
    privateLinkResourceId: privatelink.outputs.privatelinkResourceId
    logAnalyticsId: logAnalytics.id
    enablediagnostics: enablediagnostics
  }
  dependsOn: [
    privatelink
  ]
}

module privatelink '../modules/privatelinkservice.bicep' = {
  name: 'privatelinkservice'
  params:{
    privatelinkserviceName: 'privatelinkservice'
    location: locationSite1
    loadBalancerFrontendIPConfigurationsID: internalLB.outputs.loadBalancerFrontendIPConfigurations_id
    subnetID: cloud_vnet.properties.subnets[0].id
    subscriptionId: subscription().subscriptionId
  }
  dependsOn: [
    internalLB
    cloud_vnet
  ]
}


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
          privateEndpointNetworkPolicies:'Disabled'
          privateLinkServiceNetworkPolicies:'Disabled'
        }
      }
    ]
  }
}

var stinternallbName = 'internal-LB'
module internalLB '../modules/standard_internal_lb.bicep' = {
  name: stinternallbName
  params: {
    loadbalancerName: stinternallbName
    location: locationSite1
    vnetName : cloud_vnet.name
    frontendip: '10.0.0.100'
    loadbalancingRules_protocol : 'tcp'
    loadbalancingRules_frontendPort: 80
    loadbalancingRules_backendPort: 80
    loadbalancingRules_idleTimeoutInMinutes: 5
    probes_protocol: 'tcp'
    probes_port: 80
    probes_intervalInSeconds: 5
  }
}

module clientvm '../modules/ubuntu20.04.bicep' = {
  name: 'client-vm'
  params: {
    vmName: 'clientvm'
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
    subnetId: cloud_vnet.properties.subnets[0].id
    loadBalancerBackendAddressPoolsId: internalLB.outputs.loadBalancerbackendAddressPools_id
    usePublicIP: true // true にしなければ apache のインストールに失敗します。()
    customData: loadFileAsBase64('cloud-init.yml')
  }
}]

/* ****************************** enable diagnostic logs ****************************** */

var logAnalyticsWorkspace = '${uniqueString(resourceGroup().id)}la'
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = if (enablediagnostics) {
  name: logAnalyticsWorkspace
  location: locationSite1
}
