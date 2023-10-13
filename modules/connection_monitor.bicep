param location string
param connectionMonitorName string = 'conmon01'
param srcVmName string
param soruceVmResouceGroup string
param dstVmName string
param dstVmResourceGroup string = ''

@allowed([
  'Windows'
  'Linux'
])
param osType string = 'Linux'

var _soruceVmResouceGroup = soruceVmResouceGroup
var _dstVmResourceGroup = dstVmResourceGroup != '' ? dstVmResourceGroup : soruceVmResouceGroup

resource srcVm 'Microsoft.Compute/virtualMachines@2023-03-01' existing = {
  scope: resourceGroup(_soruceVmResouceGroup)
  name: srcVmName
}

resource dstVm 'Microsoft.Compute/virtualMachines@2023-03-01' existing = {
  scope: resourceGroup(_dstVmResourceGroup)
  name: dstVmName
}

var srcVmEndpoints = [
  {
    name: '${srcVmName}(${_soruceVmResouceGroup})'
    resourceId: srcVm.id
    type: 'AzureVM'
  }
]

var dstVmEndpoints = [
  {
    name: '${dstVmName}(${_dstVmResourceGroup})'
    resourceId: dstVm.id
    type: 'AzureVM'
  }
]

var endpoints = concat(srcVmEndpoints, dstVmEndpoints)

var test01Name = osType == 'Linux' ? 'ssh' : 'rdp'
var test01Port = osType == 'Linux' ? 22 : 3389
resource connection_monitor 'Microsoft.Network/networkWatchers/connectionMonitors@2023-04-01' = {
  name: 'NetworkWatcher_${location}/${connectionMonitorName}'
  location: location
  properties: {
    endpoints: endpoints
    testConfigurations: [
      {
        name: test01Name
        testFrequencySec: 30
        protocol: 'Tcp'
        successThreshold: {}
        tcpConfiguration: {
          port: test01Port
          disableTraceRoute: false
        }
      }
    ]
    testGroups: [
      {
        name: test01Name
        sources: [
          '${srcVmName}(${_soruceVmResouceGroup})'
        ]
        destinations: [
          '${dstVmName}(${_dstVmResourceGroup})'
        ]
        testConfigurations: [
          test01Name
        ]
        disable: false
      }
    ]
  }
}
