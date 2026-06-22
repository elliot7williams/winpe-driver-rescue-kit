[CmdletBinding()]
param(
    [string]$WindowsPath,
    [string[]]$DriverPath,
    [string]$LogDirectory,
    [switch]$DryRun,
    [switch]$NonInteractive
)

$ErrorActionPreference = "Stop"

function Write-Section {
    param([string]$Text)
    Write-Host ""
    Write-Host "=== $Text ===" -ForegroundColor Cyan
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

function Select-WindowsInstallation {
    param([object[]]$Installations)

    if ($WindowsPath) {
        if (-not (Test-Path (Join-Path $WindowsPath "System32\Config\SYSTEM"))) {
            throw "The supplied Windows path does not look valid: $WindowsPath"
        }
        return $WindowsPath.TrimEnd("\")
    }

    if ($Installations.Count -eq 0) {
        throw "No installed Windows volume was found. Unlock BitLocker first if the drive is encrypted."
    }

    if ($Installations.Count -eq 1 -or $NonInteractive) {
        return $Installations[0].WindowsPath
    }

    Write-Section "Installed Windows volumes"
    for ($i = 0; $i -lt $Installations.Count; $i++) {
        Write-Host "[$($i + 1)] $($Installations[$i].WindowsPath)"
    }

    do {
        $choice = Read-Host "Choose the Windows installation to repair"
        $number = 0
    } until ([int]::TryParse($choice, [ref]$number) -and $number -ge 1 -and $number -le $Installations.Count)

    $Installations[$number - 1].WindowsPath
}

function Get-CandidateDriverRoots {
    $roots = New-Object System.Collections.Generic.List[string]

    foreach ($path in $DriverPath) {
        if ($path -and (Test-Path $path)) {
            $roots.Add((Resolve-Path $path).Path)
        }
    }

    $bundled = "X:\DriverRescue\Drivers"
    if (Test-Path $bundled) {
        $roots.Add($bundled)
    }

    Get-PSDrive -PSProvider FileSystem | ForEach-Object {
        $root = $_.Root
        foreach ($folderName in @("drivers", "Drivers", "driver", "Driver")) {
            $candidate = Join-Path $root $folderName
            if (Test-Path $candidate) {
                $roots.Add($candidate)
            }
        }

        $hasInfNearRoot = Get-ChildItem -Path $root -Filter "*.inf" -File -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($hasInfNearRoot) {
            $roots.Add($root)
        }
    }

    $roots |
        Where-Object { $_ -and (Test-Path $_) } |
        Sort-Object -Unique
}

function Get-InfFiles {
    param([string[]]$Roots)

    $skipFragments = @(
        "\Windows\",
        "\Program Files\",
        "\Program Files (x86)\",
        "\ProgramData\",
        "\Recovery\",
        "\System Volume Information\",
        "\`$Recycle.Bin\"
    )

    $files = New-Object System.Collections.Generic.List[string]
    foreach ($root in $Roots) {
        Write-Host "Scanning $root"
        Get-ChildItem -Path $root -Recurse -Filter "*.inf" -File -ErrorAction SilentlyContinue | ForEach-Object {
            $fullName = $_.FullName
            $skip = $false
            foreach ($fragment in $skipFragments) {
                if ($fullName.IndexOf($fragment, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
                    $skip = $true
                    break
                }
            }
            if (-not $skip) {
                $files.Add($fullName)
            }
        }
    }

    $files | Sort-Object -Unique
}

function New-RescueLogDirectory {
    param(
        [Parameter(Mandatory)]
        [string]$TargetDrive
    )

    if ($LogDirectory) {
        New-Item -ItemType Directory -Force -Path $LogDirectory | Out-Null
        return (Resolve-Path $LogDirectory).Path
    }

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $path = Join-Path $TargetDrive "DriverRescueLogs\$timestamp"
    New-Item -ItemType Directory -Force -Path $path | Out-Null
    $path
}

Write-Section "WinPE Driver Rescue"

$installations = @(Get-WindowsInstallations)
$targetWindows = Select-WindowsInstallation -Installations $installations
$targetDrive = Split-Path -Qualifier $targetWindows
$rescueLogDirectory = New-RescueLogDirectory -TargetDrive $targetDrive
$restoreLogPath = Join-Path $rescueLogDirectory "Restore.log"
$scanLogPath = Join-Path $rescueLogDirectory "DriverScan.txt"
$driverRoots = @(Get-CandidateDriverRoots)

if ($driverRoots.Count -eq 0) {
    throw "No driver folders were found. Attach a USB drive with a drivers folder or pass -DriverPath."
}

Write-Section "Driver sources"
$driverRoots | ForEach-Object { Write-Host $_ }

$infFiles = @(Get-InfFiles -Roots $driverRoots)
if ($infFiles.Count -eq 0) {
    throw "No .inf driver files were found in the detected driver sources."
}

$scanLines = @(
    "WinPE Driver Rescue scan",
    "Timestamp: $(Get-Date -Format s)",
    "Windows path: $targetWindows",
    "",
    "Driver sources:"
) + $driverRoots + @(
    "",
    "INF files:"
) + $infFiles
$scanLines | Set-Content -Encoding ASCII -Path $scanLogPath

Write-Section "Restore target"
Write-Host "Windows path: $targetWindows"
Write-Host "Driver count: $($infFiles.Count)"
Write-Host "Log folder:   $rescueLogDirectory"
Write-Host "Scan log:     $scanLogPath"

if ($DryRun) {
    Write-Section "Dry run"
    Write-Host "No drivers were installed."
    Write-Host "The following .inf files would be added:"
    $infFiles | ForEach-Object { Write-Host $_ }
    Write-Host ""
    Write-Host "Scan log written to: $scanLogPath"
    exit 0
}

if (-not $NonInteractive) {
    $answer = Read-Host "Install these drivers into $targetWindows? Type YES to continue"
    if ($answer -ne "YES") {
        Write-Host "Cancelled."
        exit 2
    }
}

Write-Section "Installing drivers"
$imageRoot = "$targetDrive\"
$imageArg = "/Image:$imageRoot"
$success = 0
$failed = 0

@(
    "WinPE Driver Rescue restore",
    "Timestamp: $(Get-Date -Format s)",
    "Windows path: $targetWindows",
    "Driver count: $($infFiles.Count)",
    ""
) | Set-Content -Encoding ASCII -Path $restoreLogPath

foreach ($inf in $infFiles) {
    Write-Host "Adding $inf"
    dism.exe $imageArg /Add-Driver "/Driver:$inf" | Tee-Object -FilePath $restoreLogPath -Append
    if ($LASTEXITCODE -eq 0) {
        $success++
    } else {
        $failed++
        "FAILED: $inf (exit code $LASTEXITCODE)" | Tee-Object -FilePath $restoreLogPath -Append
    }
}

Write-Section "Complete"
Write-Host "Installed successfully: $success"
Write-Host "Failed:                 $failed"
Write-Host "Restore log:            $restoreLogPath"
Write-Host "Scan log:               $scanLogPath"
Write-Host ""
Write-Host "Reboot and test Windows. If hardware is still missing, add the vendor's full driver package to USB and run this again."
