<#
.SYNOPSIS
Generates a WinPE driver rescue environment report.

.DESCRIPTION
Creates SystemReport.txt with detected Windows installations, file-system
drives, driver source folders, .inf counts, DiskPart volume output, WinPE driver
output, network configuration, and BitLocker status.

.PARAMETER WindowsPath
Optional path to the target Windows folder. Used to choose the default report
folder when supplied.

.PARAMETER OutputDirectory
Custom folder where SystemReport.txt should be written. If omitted, a timestamped
folder is created under DriverRescueLogs on the detected target Windows drive.

.EXAMPLE
powershell -ExecutionPolicy Bypass -File X:\Tools\Generate-RescueReport.ps1

Generates SystemReport.txt from the WinPE rescue environment.
#>

[CmdletBinding()]
param(
    [string]$WindowsPath,
    [string]$OutputDirectory
)

$ErrorActionPreference = "Stop"

function Write-Section {
    param([string]$Text)
    Write-Output ""
    Write-Output "=== $Text ==="
}

function Get-WindowsInstallations {
    $installations = @()

    Get-PSDrive -PSProvider FileSystem | ForEach-Object {
        $candidate = Join-Path $_.Root "Windows"
        if ((Test-Path (Join-Path $candidate "System32\Config\SYSTEM")) -and
            (Test-Path (Join-Path $candidate "System32\DriverStore"))) {
            $installations += [pscustomobject]@{
                Drive = $_.Root
                WindowsPath = $candidate.TrimEnd("\")
            }
        }
    }

    $installations
}

function Get-DefaultReportDirectory {
    param([object[]]$Installations)

    if ($OutputDirectory) {
        New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
        return (Resolve-Path $OutputDirectory).Path
    }

    $targetDrive = $null
    if ($WindowsPath) {
        $targetDrive = Split-Path -Qualifier $WindowsPath
    } elseif ($Installations.Count -gt 0) {
        $targetDrive = Split-Path -Qualifier $Installations[0].WindowsPath
    }

    if (-not $targetDrive) {
        $targetDrive = "X:"
    }

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $path = Join-Path $targetDrive "DriverRescueLogs\$timestamp"
    New-Item -ItemType Directory -Force -Path $path | Out-Null
    $path
}

function Get-DriverRoots {
    $roots = New-Object System.Collections.Generic.List[string]

    $bundled = "X:\DriverRescue\Drivers"
    if (Test-Path $bundled) {
        $roots.Add($bundled)
    }

    Get-PSDrive -PSProvider FileSystem | ForEach-Object {
        foreach ($folderName in @("drivers", "Drivers", "driver", "Driver")) {
            $candidate = Join-Path $_.Root $folderName
            if (Test-Path $candidate) {
                $roots.Add($candidate)
            }
        }
    }

    $roots | Sort-Object -Unique
}

function Invoke-ReportCommand {
    param(
        [string]$Title,
        [string]$Command,
        [string[]]$Arguments = @()
    )

    Write-Section $Title
    try {
        & $Command @Arguments 2>&1 | ForEach-Object { $_ }
    } catch {
        "Unable to run $Command`: $($_.Exception.Message)"
    }
}

$installations = @(Get-WindowsInstallations)
$reportDirectory = Get-DefaultReportDirectory -Installations $installations
$reportPath = Join-Path $reportDirectory "SystemReport.txt"

$report = @()
$report += "WinPE Driver Rescue report"
$report += "Timestamp: $(Get-Date -Format s)"
$report += "Computer name: $env:COMPUTERNAME"
$report += "Report path: $reportPath"

$report += Write-Section "Windows installations"
if ($installations.Count -eq 0) {
    $report += "No installed Windows volume was found."
} else {
    $report += ($installations | Format-Table -AutoSize | Out-String)
}

$report += Write-Section "File system drives"
$report += (Get-PSDrive -PSProvider FileSystem | Format-Table Name, Root, Used, Free -AutoSize | Out-String)

$report += Write-Section "Driver source folders"
$driverRoots = @(Get-DriverRoots)
if ($driverRoots.Count -eq 0) {
    $report += "No driver source folders were found."
} else {
    $report += $driverRoots
}

$report += Write-Section "Driver INF count"
foreach ($root in $driverRoots) {
    $count = @(Get-ChildItem -Path $root -Recurse -Filter "*.inf" -File -ErrorAction SilentlyContinue).Count
    $report += "$root : $count"
}

$report += Invoke-ReportCommand -Title "DiskPart volumes" -Command "cmd.exe" -Arguments @("/c", "echo list volume | diskpart")
$report += Invoke-ReportCommand -Title "DISM detected drivers in WinPE" -Command "dism.exe" -Arguments @("/Online", "/Get-Drivers", "/Format:Table")
$report += Invoke-ReportCommand -Title "Network configuration" -Command "ipconfig.exe" -Arguments @("/all")
$report += Invoke-ReportCommand -Title "BitLocker status" -Command "manage-bde.exe" -Arguments @("-status")

$report | Set-Content -Encoding ASCII -Path $reportPath

Write-Host "Rescue report written to: $reportPath"
