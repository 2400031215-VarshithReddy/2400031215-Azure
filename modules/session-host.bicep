targetScope = 'resourceGroup'

@description('Azure region')
param location string

@description('Subnet ARM ID')
param subnetId string

@description('NSG ARM ID')
param nsgId string

@description('Virtual Machine Name')
param vmName string

@description('Virtual Machine SKU')
param vmSize string

@description('Local administrator username')
param adminUsername string

@description('Local administrator password')
@secure()
param adminPassword string

@description('AVD Host Pool registration token')
@secure()
param hostPoolToken string

@description('AVD Host Pool Name')
param hostPoolName string

@description('Auto-shutdown time (HHmm format in UTC)')
param autoShutdownTime string

@description('Auto-shutdown timezone')
param autoShutdownTimeZone string

// Network Interface
resource nic 'Microsoft.Network/networkInterfaces@2023-11-01' = {
  name: '${vmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetId
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsgId
    }
  }
}

// Windows 11 Multi-Session VM
resource vm 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: vmName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: take(vmName, 15)
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsDesktop'
        offer: 'windows-11'
        sku: 'win11-23h2-avd'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
        deleteOption: 'Delete'
        diskSizeGB: 128
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
    licenseType: 'Windows_Client'
  }
}

// Microsoft Entra ID Join Extension
resource aadJoinExtension 'Microsoft.Compute/virtualMachines/extensions@2024-03-01' = {
  parent: vm
  name: 'AADLoginForWindows'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: 'AADLoginForWindows'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      mdmId: ''
    }
  }
}

// AVD DSC Extension (Registers Session Host to Host Pool)
resource dscExtension 'Microsoft.Compute/virtualMachines/extensions@2024-03-01' = {
  parent: vm
  name: 'Microsoft.PowerShell.DSC'
  location: location
  dependsOn: [
    aadJoinExtension
  ]
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.77'
    autoUpgradeMinorVersion: true
    settings: {
      modulesUrl: 'https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_1.0.02714.342.zip'
      configurationFunction: 'Configuration.ps1\\AddSessionHost'
      properties: {
        hostPoolName: hostPoolName
        registrationInfoToken: hostPoolToken
        aadJoin: true
      }
    }
  }
}

// Auto-Shutdown Schedule (Cost Safeguard)
resource autoShutdown 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: 'shutdown-computevm-${vm.name}'
  location: location
  properties: {
    status: 'Enabled'
    taskType: 'ComputeVmShutdownTask'
    dailyRecurrence: {
      time: autoShutdownTime
    }
    timeZoneId: autoShutdownTimeZone
    targetResourceId: vm.id
    notificationSettings: {
      status: 'Disabled'
    }
  }
}

output vmId string = vm.id
output vmName string = vm.name
output nicId string = nic.id
