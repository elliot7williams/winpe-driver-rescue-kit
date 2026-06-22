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

