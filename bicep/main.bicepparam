using 'main.bicep'

param location = 'indiasouthcentral'
param existingVnetName = 'vnet-avd-lab'
param existingSubnetName = 'snet-avd'
param existingStorageAccountName = 'stavdprofiles260916'
param existingFileShareName = 'fslogix'
param hostPoolName = 'hp-avd-engineering-lab'
param hostPoolType = 'Pooled'
param loadBalancerType = 'BreadthFirst'
param maxSessionLimit = 5
param appGroupName = 'dag-avd-engineering-lab'
param workspaceName = 'ws-avd-engineering-lab'
param adminUsername = 'avdadmin'
param adminPassword = 'Password#123456!' // Placeholder: User will provide secure secret before actual deployment
param vmSize = 'Standard_D4s_v5'
param autoShutdownTime = '1800'
param autoShutdownTimeZone = 'India Standard Time'
