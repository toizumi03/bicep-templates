param virtualhubName string
param location string
param vhubAddressPrefix string
param allowBranchToBranchTraffic bool
param virtualwanId string

resource virtualhub 'Microsoft.Network/virtualhubs@2023-04-01' = {
  name: virtualhubName
  location: location
  properties: {
    addressPrefix: vhubAddressPrefix
    allowBranchToBranchTraffic: allowBranchToBranchTraffic
    virtualWan: {
      id: virtualwanId
    }
  }
}

output vitualhubname string = virtualhub.name
output virtualhubId string = virtualhub.id
