targetScope = 'resourceGroup'

@description('Azure region')
param location string

@description('Name of the Network Security Group')
param nsgName string

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      // Outbound rules
      {
        name: 'Allow-AVD-Traffic-Outbound'
        properties: {
          priority: 100
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'AzureCloud'
          description: 'Allows outbound reverse connect session host traffic to AVD management plane'
        }
      }
      {
        name: 'Allow-Azure-Storage-Outbound'
        properties: {
          priority: 110
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRanges: [
            '445'
            '443'
          ]
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Storage'
          description: 'Allows SMB (445) and HTTPS (443) traffic to Azure Files for FSLogix'
        }
      }
      {
        name: 'Allow-KMS-Outbound'
        properties: {
          priority: 120
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '1688'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          description: 'Allows Windows activation via KMS'
        }
      }
    ]
  }
}

output nsgId string = nsg.id
output nsgName string = nsg.name
