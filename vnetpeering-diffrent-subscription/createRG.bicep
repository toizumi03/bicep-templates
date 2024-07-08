targetScope = 'subscription'
param rglocation string
param rgname string

resource newRG 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rgname
  location: rglocation
}
