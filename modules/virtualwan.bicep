param virtualwanName string
param location string
param allowBranchToBranchTraffic bool = true
param allowVnetToVnetTraffic bool = true
param disableVpnEncryption bool = false

resource virtualwan 'Microsoft.Network/virtualWans@2023-04-01' = {
  name: virtualwanName
  location: location
  properties: {
    allowBranchToBranchTraffic: allowBranchToBranchTraffic
    allowVnetToVnetTraffic: allowVnetToVnetTraffic
    disableVpnEncryption: disableVpnEncryption
  }
}

output virtualwanName string = virtualwan.name
output virtualwanId string = virtualwan.id

