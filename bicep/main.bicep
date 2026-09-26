targetScope = 'resourceGroup'

@description('Azure region for the AVD deployment')
param location string = resourceGroup().location

@description('Name of the existing Virtual Network')
param existingVnetName string = 'vnet-avd-lab'

@description('Name of the existing Subnet')
param existingSubnetName string = 'snet-avd'


@description('Name of the AVD Host Pool')
param hostPoolName string = 'hp-avd-engineering-lab'

@description('Host Pool Type')
@allowed([
  'Pooled'
  'Personal'
])
param hostPoolType string = 'Pooled'

@description('Load balancing algorithm for pooled host pool')
@allowed([
  'BreadthFirst'
  'DepthFirst'
])
param loadBalancerType string = 'BreadthFirst'

@description('Max concurrent sessions per session host')
param maxSessionLimit int = 5

@description('Name of the Desktop Application Group')
param appGroupName string = 'dag-avd-engineering-lab'

@description('Name of the AVD Workspace')
param workspaceName string = 'ws-avd-engineering-lab'

@description('Session host VM admin username')
param adminUsername string = 'labadmin'

@description('Session host VM admin password')
@secure()
param adminPassword string

@description('VM Size for test session host (optimized for general compute/engineering testing within student budget/quota)')
param vmSize string = 'Standard_D4s_v5'

@description('Auto-shutdown time in 24h format (UTC), e.g. 1800 for 6:00 PM UTC')
param autoShutdownTime string = '1800'

@description('Auto-shutdown timezone')
param autoShutdownTimeZone string = 'India Standard Time'

// Reference existing network resources
resource existingVnet 'Microsoft.Network/virtualNetworks@2023-11-01' existing = {
  name: existingVnetName
}

resource existingSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' existing = {
  parent: existingVnet
  name: existingSubnetName
}


// Module 1: AVD Control Plane (Host Pool, Application Group, Workspace)
module avdControlPlane 'modules/avd-control-plane.bicep' = {
  name: 'avdControlPlaneDeployment'
  params: {
    location: location
    hostPoolName: hostPoolName
    hostPoolType: hostPoolType
    loadBalancerType: loadBalancerType
    maxSessionLimit: maxSessionLimit
    appGroupName: appGroupName
    workspaceName: workspaceName
  }
}

// Module 2: Network Security Group (for safe outbound connectivity and AVD communication)
module networkSecurity 'modules/network.bicep' = {
  name: 'networkSecurityDeployment'
  params: {
    location: location
    nsgName: 'nsg-avd-lab'
  }
}

// Module 3: Session Host VM (Single initial test VM with Entra Join and AVD Agent)
module sessionHost 'modules/session-host.bicep' = {
  name: 'sessionHostDeployment'
  params: {
    location: location
    subnetId: existingSubnet.id
    nsgId: networkSecurity.outputs.nsgId
    vmName: 'vm-avd-sh-0'
    vmSize: vmSize
    adminUsername: adminUsername
    adminPassword: adminPassword
    hostPoolToken: avdControlPlane.outputs.registrationToken
    hostPoolName: avdControlPlane.outputs.hostPoolName
    autoShutdownTime: autoShutdownTime
    autoShutdownTimeZone: autoShutdownTimeZone
  }
}

output hostPoolId string = avdControlPlane.outputs.hostPoolId
output workspaceId string = avdControlPlane.outputs.workspaceId
output appGroupId string = avdControlPlane.outputs.appGroupId
output sessionHostId string = sessionHost.outputs.vmId
