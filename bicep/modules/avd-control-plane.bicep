targetScope = 'resourceGroup'

@description('Azure region')
param location string

@description('Name of the Host Pool')
param hostPoolName string

@description('Host Pool Type')
param hostPoolType string

@description('Load balancer algorithm')
param loadBalancerType string

@description('Max concurrent sessions per host')
param maxSessionLimit int

@description('Application Group Name')
param appGroupName string

@description('Workspace Name')
param workspaceName string

@description('Expiration time for host pool registration token (ISO 8601)')
param tokenExpirationTime string = dateTimeAdd(utcNow(), 'PT24H')

// Host Pool
resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2024-04-03' = {
  name: hostPoolName
  location: location
  properties: {
    hostPoolType: hostPoolType
    loadBalancerType: loadBalancerType
    preferredAppGroupType: 'Desktop'
    maxSessionLimit: maxSessionLimit
    validationEnvironment: false
    customRdpProperty: 'targetisaadjoined:i:1;audiocapturemode:i:1;audiomode:i:0;drivestoredirect:s:*;autoreconnection enabled:i:1;'
    registrationInfo: {
      expirationTime: tokenExpirationTime
      registrationTokenOperation: 'Update'
    }
  }
}

// Desktop Application Group
resource appGroup 'Microsoft.DesktopVirtualization/applicationGroups@2024-04-03' = {
  name: appGroupName
  location: location
  properties: {
    applicationGroupType: 'Desktop'
    hostPoolArmPath: hostPool.id
    description: 'Engineering Lab Desktop Application Group'
    friendlyName: 'Engineering Lab Desktops'
  }
}

// Workspace
resource workspace 'Microsoft.DesktopVirtualization/workspaces@2024-04-03' = {
  name: workspaceName
  location: location
  properties: {
    description: 'Engineering Lab AVD Workspace for Students'
    friendlyName: 'Engineering Software Lab'
    applicationGroupReferences: [
      appGroup.id
    ]
  }
}

output hostPoolId string = hostPool.id
output hostPoolName string = hostPool.name
output registrationToken string = hostPool.properties.registrationInfo.token
output appGroupId string = appGroup.id
output workspaceId string = workspace.id
