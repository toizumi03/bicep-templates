param siteName string
param location string 
param siteAddressPrefix string
param bgpasn int
param bgpPeeringAddress string
param linkSpeedInMbps int
param vpnDeviceIpAddress string
param wanId string

resource vpnSite 'Microsoft.Network/vpnSites@2023-04-01' = {
  name: siteName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        siteAddressPrefix
      ]
    }
    bgpProperties: {
      asn: bgpasn
      bgpPeeringAddress: bgpPeeringAddress
      peerWeight: 0
    }
    deviceProperties: {
      linkSpeedInMbps: linkSpeedInMbps
    }
    ipAddress: vpnDeviceIpAddress
    virtualWan: {
      id: wanId
    }
  }
}

output resourceId string = vpnSite.id
output resourceName string = vpnSite.name
output vpnsiteid string = vpnSite.id

