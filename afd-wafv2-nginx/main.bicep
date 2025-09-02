
param locationSite1 string 
param vmAdminUsername string 
@secure()
param vmAdminPassword string
param frontDoorEndpointName string = 'afd-${uniqueString(resourceGroup().id)}'
@description('The name of the SKU to use when creating the Front Door profile.')
@allowed([
  'Standard_AzureFrontDoor'
  'Premium_AzureFrontDoor'
])
param frontDoorSkuName string = 'Standard_AzureFrontDoor'
var frontDoorProfileName = 'test-afd'
var frontDoorOriginGroupName = 'test-OriginGroup1'
var frontDoorOriginName = 'testServiceOrigin1'
var frontDoorRouteName = 'testRoute1'

/*******************origin server setting*********************/

resource cloud_vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
	name: 'cloud-vnet'
	location: locationSite1
	properties: {
		addressSpace: {
			addressPrefixes: [ '10.0.0.0/16' ]
		}
		subnets: [
			{
				name: 'defaultt'
				properties: {
					addressPrefix: '10.0.1.0/24'
				}
			}
		]
	}
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2024-07-01' = {
	name: 'nginx-nsg'
	location: locationSite1
	properties: {
		securityRules: [
			{
				name: 'AllowHTTP'
				properties: {
					priority: 1001
					direction: 'Inbound'
					access: 'Allow'
					protocol: 'Tcp'
					sourcePortRange: '*'
					destinationPortRange: '80'
					sourceAddressPrefix: '*'
					destinationAddressPrefix: '*'
				}
			}
			{
				name: 'AllowHTTPS'
				properties: {
					priority: 1002
					direction: 'Inbound'
					access: 'Allow'
					protocol: 'Tcp'
					sourcePortRange: '*'
					destinationPortRange: '443'
					sourceAddressPrefix: '*'
					destinationAddressPrefix: '*'
				}
			}
			{
				name: 'AllowSSH'
				properties: {
					priority: 1003
					direction: 'Inbound'
					access: 'Allow'
					protocol: 'Tcp'
					sourcePortRange: '*'
					destinationPortRange: '22'
					sourceAddressPrefix: '*'
					destinationAddressPrefix: '*'
				}
			}
		]
	}
}

resource pip 'Microsoft.Network/publicIPAddresses@2024-07-01' = {
	name: 'nginx-pip'
	location: locationSite1
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
	properties: {
    publicIPAllocationMethod: 'Static'
    deleteOption: 'Delete'
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2023-09-01' = {
	name: 'nginx-nic'
	location: locationSite1
	properties: {
		ipConfigurations: [
			{
				name: 'ipconfig1'
				properties: {
					subnet: {
						id: cloud_vnet.properties.subnets[0].id
					}
					privateIPAllocationMethod: 'Dynamic'
					publicIPAddress: {
						id: pip.id
					}
				}
			}
		]
		networkSecurityGroup: {
			id: nsg.id
		}
	}
}

resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
	name: 'nginxvm'
	location: locationSite1
	properties: {
		hardwareProfile: {
			vmSize: 'Standard_B1s'
		}
		osProfile: {
			computerName: 'nginxvm'
			adminUsername: vmAdminUsername
			adminPassword: vmAdminPassword
			customData: loadFileAsBase64('nginx.yml')
		}
		storageProfile: {
			imageReference: {
				publisher: 'Canonical'
				offer: '0001-com-ubuntu-server-focal'
				sku: '20_04-lts-gen2'
				version: 'latest'
			}
			osDisk: {
				createOption: 'FromImage'
			}
		}
		networkProfile: {
			networkInterfaces: [
				{
					id: nic.id
				}
			]
		}
	}
}

/*******************AFD Setting*********************/

resource frontDoorProfile 'Microsoft.Cdn/profiles@2025-06-01' = {
  name: frontDoorProfileName
  location: 'global'
  sku: {
    name: frontDoorSkuName
  }
}

resource frontDoorEndpoint 'Microsoft.Cdn/profiles/afdEndpoints@2025-06-01' = {
  name: frontDoorEndpointName
  parent: frontDoorProfile
  location: 'global'
  properties: {
    enabledState: 'Enabled'
  }
}

resource frontDoorOriginGroup 'Microsoft.Cdn/profiles/originGroups@2025-06-01' = {
  name: frontDoorOriginGroupName
  parent: frontDoorProfile
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
    }
    healthProbeSettings: {
      probePath: '/'
      probeRequestType: 'HEAD'
      probeProtocol: 'Http'
      probeIntervalInSeconds: 100
    }
  }
}

resource frontDoorOrigin 'Microsoft.Cdn/profiles/originGroups/origins@2025-06-01' = {
  name: frontDoorOriginName
  parent: frontDoorOriginGroup
  properties: {
    hostName: pip.properties.ipAddress
    httpPort: 80
    httpsPort: 443
    originHostHeader: pip.properties.ipAddress
    priority: 1
    weight: 1000
  }
}

resource frontDoorRoute 'Microsoft.Cdn/profiles/afdEndpoints/routes@2025-06-01' = {
  name: frontDoorRouteName
  parent: frontDoorEndpoint
  dependsOn: [
    frontDoorOrigin
  ]
  properties: {
    originGroup: {
      id: frontDoorOriginGroup.id
    }
    supportedProtocols: [
      'Http'
      'Https'
    ]
    patternsToMatch: [
      '/*'
    ]
    forwardingProtocol: 'HttpOnly'
    linkToDefaultDomain: 'Enabled'
    httpsRedirect: 'Disabled'
  }
}

resource securityPolicy 'Microsoft.Cdn/profiles/securityPolicies@2025-04-15' = {
  name: 'afdsecuritypolicy'
  parent: frontDoorProfile
  properties: {
    parameters: {
      type: 'WebApplicationFirewall'
      wafPolicy: {
        id: wafPolicy.id
      }
      associations: [
        {
          domains: [
            {
              id: frontDoorEndpoint.id
            }
          ]
          patternsToMatch: [
            '/*'
          ]
        }
      ]
    }
  }
}

/*******************WAF Setting*********************/

resource wafPolicy 'Microsoft.Network/frontDoorWebApplicationFirewallPolicies@2020-11-01' = {
  name: 'afdwafpolicy'
  location: 'global'
  sku: {
    name: frontDoorSkuName
  }
  properties: {
    policySettings: {
      enabledState: 'Enabled'
      mode: 'Detection'
    }
  }
}
