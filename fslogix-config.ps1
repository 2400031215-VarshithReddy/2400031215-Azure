<#
.SYNOPSIS
    Configures FSLogix Profile Container for Azure Files with Microsoft Entra Kerberos.
.DESCRIPTION
    Applies recommended FSLogix registry settings to mount user profiles from
    \\stavdprofiles260916.file.core.windows.net\fslogix.
#>

[CmdletBinding()]
param(
    [string]$StorageAccountName = "stavdprofiles260916",
    [string]$FileShareName = "fslogix"
)

$SharePath = "\\$StorageAccountName.file.core.windows.net\$FileShareName"
Write-Host "Configuring FSLogix profile container target: $SharePath"

$fslogixRegPath = "HKLM:\SOFTWARE\FSLogix\Profiles"
if (-not (Test-Path $fslogixRegPath)) {
    New-Item -Path $fslogixRegPath -Force | Out-Null
}

# Core FSLogix Profile Settings
Set-ItemProperty -Path $fslogixRegPath -Name "Enabled" -Value 1 -Type DWord
Set-ItemProperty -Path $fslogixRegPath -Name "VHDLocations" -Value @($SharePath) -Type MultiString
Set-ItemProperty -Path $fslogixRegPath -Name "VolumeType" -Value "VHDX" -Type String
Set-ItemProperty -Path $fslogixRegPath -Name "IsDynamic" -Value 1 -Type DWord
Set-ItemProperty -Path $fslogixRegPath -Name "SizeInMBs" -Value 30720 -Type DWord # 30 GB max container
Set-ItemProperty -Path $fslogixRegPath -Name "DeleteLocalProfileWhenVHDShouldApply" -Value 1 -Type DWord
Set-ItemProperty -Path $fslogixRegPath -Name "PreventLoginWithFailure" -Value 0 -Type DWord
Set-ItemProperty -Path $fslogixRegPath -Name "PreventLoginWithTempProfile" -Value 1 -Type DWord

# Enable Entra Kerberos ticket retrieval for cloud-joined machines
$lsaRegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\Kerberos\Parameters"
if (-not (Test-Path $lsaRegPath)) {
    New-Item -Path $lsaRegPath -Force | Out-Null
}
Set-ItemProperty -Path $lsaRegPath -Name "CloudKerberosTicketRetrievalEnabled" -Value 1 -Type DWord

Write-Host "FSLogix profile container configuration applied successfully."
