param locationSite1 string
param vmAdminUsername string
@secure()
param vmAdminPassword string
param enablediagnostics bool
param enabledBastion bool

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
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '10.0.3.0/24'
        }
      }
    ]
  }
}

module appgwwafv2 '../modules/applicationgateway.bicep' ={
  name: 'appgw-wafv2'
  params:{
    location: locationSite1
    appGwName: 'appgw-wafv2'
    maxCapacity: 5
    minCapacity: 0
    backendHttpSettings_port: 80
    backendHttpSettings_protocol: 'Http'
    subnet_id: cloud_vnet.properties.subnets[1].id
    backendVMPrivateIPs:[for i in range(0,numberOfInstances):backendvms[i].outputs.privateIP]
    enablediagnostics: enablediagnostics
    wafPolicyId: wafPolicy.outputs.policyId
    logAnalyticsID: logAnalytics.id
  }
}

/* ****************************** WAF Policy ****************************** */
 
module wafPolicy '../modules/applicationgatewaywaf.bicep' = {
  name: 'wafPolicy'
  params: {
    wafName: 'appGwWafPolicy'
    location: locationSite1
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
  }
}]

/* ****************************** enable Bastion ****************************** */

module bastion '../modules/bastion.bicep' = if(enabledBastion){
  name:'azureBastion' 
  params: {
    bastionName: 'azureBastion'
    location: locationSite1
    bastionsku: 'Standard'
    subnetid: cloud_vnet.properties.subnets[3].id
  }
}

/* ****************************** enable diagnostic logs ****************************** */

var logAnalyticsWorkspace = '${uniqueString(resourceGroup().id)}la'
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = if (enablediagnostics) {
  name: logAnalyticsWorkspace
  location: locationSite1
}