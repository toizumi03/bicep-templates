param appGwName string
param location string
param maxCapacity int
param minCapacity int
param backendHttpSettings_port int
param backendHttpSettings_protocol string
param subnet_id string
param backendVMPrivateIPs array
param enablediagnostics bool = false
param logAnalyticsID string

resource AppGWfrontendIP 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: '${appGwName}-pip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'static'
  }
}

resource applicationgateway 'Microsoft.Network/applicationGateways@2023-04-01' = {
  name: appGwName
  location: location
  tags: {
    tagName1: 'toizumi_recipes'
  }
  properties: {
    sku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
    }
    autoscaleConfiguration: {
      maxCapacity: maxCapacity
      minCapacity: minCapacity
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: subnet_id
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGwPublicFrontendIp'
        properties: {
          publicIPAddress: {
            id: AppGWfrontendIP.id
          }
        }
      }
      {
        name: 'appGwPrivateFrontendIp'
        properties: {
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: subnet_id
          }
          privateIPAddress: '10.0.1.10'
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port_80'
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'BackendPool1'
        properties:{
          backendAddresses:[
            for ip in backendVMPrivateIPs:{
              ipAddress: ip
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'backendHttpSettings'
        properties: {
          cookieBasedAffinity: 'Disabled'
          port: backendHttpSettings_port
          protocol: backendHttpSettings_protocol
        }
      }
    ]
    httpListeners: [
      {
        name: 'http-lisner'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appGwName, 'appGwPublicFrontendIp')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGwName, 'port_80')
          }
          protocol: 'Http'
          requireServerNameIndication: false
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'requestRoutingRule1'
        properties: {
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGwName, 'BackendPool1')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGwName, 'backendHttpSettings')
          }
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appGwName, 'http-lisner')
          }
          priority: 100
          ruleType: 'Basic'
        }
      }
    ]
    webApplicationFirewallConfiguration: {
      fileUploadLimitInMb: 100
      enabled: true
      firewallMode: 'Detection'
      maxRequestBodySizeInKb: 128
      requestBodyCheck: true
      ruleSetType: 'OWASP'
      ruleSetVersion: '3.2'
    }
  }
}


/* ****************************** enable diagnostic logs ****************************** */

resource diagnosticLogs 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enablediagnostics){
  name: appGwName
  scope: applicationgateway
  properties: {
    workspaceId: logAnalyticsID
    logs: [
      {
        category: null
        categoryGroup: 'allLogs'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
  }
}

output appgw_backendpool_id string = applicationgateway.properties.backendAddressPools[0].id
