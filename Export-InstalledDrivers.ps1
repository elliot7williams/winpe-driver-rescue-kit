<#
.SYNOPSIS
Exports installed third-party drivers from a working Windows system.

.DESCRIPTION
Uses DISM to export third-party drivers from the running Windows installation to
a destination folder. The exported folder can be copied to external media and
used by the WinPE Driver Rescue ISO.

.PARAMETER Destination
Folder where exported driver packages will be written.

.EXAMPLE
.\Export-InstalledDrivers.ps1 -Destination E:\drivers

Exports installed third-party drivers to E:\drivers.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Destination
)

$ErrorActionPreference = "Stop"

New-Item -ItemType Directory -Force -Path $Destination | Out-Null

Write-Host "Exporting third-party drivers to $Destination"
dism.exe /Online /Export-Driver "/Destination:$Destination"

if ($LASTEXITCODE -ne 0) {
    throw "Driver export failed with exit code $LASTEXITCODE"
}

Write-Host "Driver export complete."
