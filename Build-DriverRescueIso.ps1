<#
.SYNOPSIS
Builds a bootable WinPE driver rescue ISO.

.DESCRIPTION
Creates a Windows PE workspace, adds the WinPE optional components required for
PowerShell-based rescue tools, copies the Driver Rescue scripts into the image,
optionally bundles local driver packages, and creates a bootable ISO.

This script must run from an elevated PowerShell session on Windows with the
Windows ADK and Windows PE add-on installed.

.PARAMETER Architecture
Target WinPE architecture. The default is amd64.

.PARAMETER Locale
WinPE optional component language pack locale. The default is en-us.

.PARAMETER OutputDirectory
Directory where the WinPE workspace, mount folder, and ISO are created.

.PARAMETER IsoName
Name of the generated ISO file. The default is DriverRescue.iso.

.PARAMETER DriverSource
Local folder containing optional driver packages to bundle into the ISO.

.PARAMETER BuildLogPath
Path to the build transcript log. The default is Build.log in the output
directory.

.PARAMETER Force
Removes existing build output before creating a new ISO.

.EXAMPLE
.\Build-DriverRescueIso.ps1

Builds .\out\DriverRescue.iso.

.EXAMPLE
.\Build-DriverRescueIso.ps1 -Force

Rebuilds the ISO after removing prior output.
#>

#Requires -RunAsAdministrator
[CmdletBinding()]
param(
    [string]$Architecture = "amd64",
    [string]$Locale = "en-us",
    [string]$OutputDirectory = "$PSScriptRoot\out",
    [string]$IsoName = "DriverRescue.iso",
    [string]$DriverSource = "$PSScriptRoot\drivers",
    [string]$BuildLogPath,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

function Find-AdkDeploymentTools {
    $candidateRoots = @(
        "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit",
        "$env:ProgramFiles\Windows Kits\10\Assessment and Deployment Kit"
    )

    foreach ($root in $candidateRoots) {
        $copype = Join-Path $root "Windows Preinstallation Environment\copype.cmd"
        $makewinpemedia = Join-Path $root "Windows Preinstallation Environment\MakeWinPEMedia.cmd"
        $dism = Join-Path $root "Deployment Tools\$Architecture\DISM\dism.exe"
        $optionalComponents = Join-Path $root "Windows Preinstallation Environment\$Architecture\WinPE_OCs"

        if ((Test-Path $copype) -and (Test-Path $makewinpemedia)) {
            return [pscustomobject]@{
                Root = $root
                CopyPe = $copype
                MakeWinPeMedia = $makewinpemedia
                Dism = $dism
                OptionalComponents = $optionalComponents
            }
        }
    }

    throw "Windows ADK with the Windows PE add-on was not found. Install both from https://learn.microsoft.com/windows-hardware/get-started/adk-install"
}

function Invoke-Native {
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [Parameter()]
        [string[]]$Arguments = @()
    )

    Write-Host "Running: $FilePath $($Arguments -join ' ')"
    & $FilePath @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed with exit code $LASTEXITCODE`: $FilePath"
    }
}

function Add-WinPeOptionalComponent {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    $packagePath = Join-Path $adk.OptionalComponents "$Name.cab"
    $languagePath = Join-Path $adk.OptionalComponents "$Locale\$Name`_$Locale.cab"

    if (-not (Test-Path $packagePath)) {
        throw "Missing WinPE optional component: $packagePath"
    }

    Invoke-Native -FilePath "dism.exe" -Arguments @("/Image:$mountRoot", "/Add-Package", "/PackagePath:$packagePath")

    if (Test-Path $languagePath) {
        Invoke-Native -FilePath "dism.exe" -Arguments @("/Image:$mountRoot", "/Add-Package", "/PackagePath:$languagePath")
    }
}

New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null

if (-not $BuildLogPath) {
    $BuildLogPath = Join-Path $OutputDirectory "Build.log"
}

$transcriptStarted = $false
try {
    Start-Transcript -Path $BuildLogPath -Force | Out-Null
    $transcriptStarted = $true
    Write-Host "Build log: $BuildLogPath"
} catch {
    Write-Warning "Could not start build transcript at $BuildLogPath`: $($_.Exception.Message)"
}

try {
$adk = Find-AdkDeploymentTools
$workRoot = Join-Path $OutputDirectory "work"
$mediaRoot = Join-Path $workRoot "media"
$mountRoot = Join-Path $OutputDirectory "mount"
$isoPath = Join-Path $OutputDirectory $IsoName

if ((Test-Path $workRoot) -or (Test-Path $mountRoot) -or (Test-Path $isoPath)) {
    if (-not $Force) {
        throw "Output already exists. Re-run with -Force to overwrite: $OutputDirectory"
    }

    if (Test-Path $mountRoot) {
        try {
            dism /Unmount-Image /MountDir:$mountRoot /Discard | Out-Null
        } catch {
            Write-Warning "Could not unmount prior image at $mountRoot. Continuing cleanup."
        }
    }

    Remove-Item -Recurse -Force $workRoot, $mountRoot, $isoPath -ErrorAction SilentlyContinue
}

Invoke-Native -FilePath $adk.CopyPe -Arguments @($Architecture, $workRoot)

$bootWim = Join-Path $mediaRoot "sources\boot.wim"
New-Item -ItemType Directory -Force -Path $mountRoot | Out-Null
Invoke-Native -FilePath "dism.exe" -Arguments @("/Mount-Image", "/ImageFile:$bootWim", "/Index:1", "/MountDir:$mountRoot")

try {
    foreach ($component in @(
        "WinPE-WMI",
        "WinPE-NetFX",
        "WinPE-Scripting",
        "WinPE-PowerShell",
        "WinPE-StorageWMI",
        "WinPE-DismCmdlets"
    )) {
        Add-WinPeOptionalComponent -Name $component
    }

    $toolsPath = Join-Path $mountRoot "Tools"
    $rescuePath = Join-Path $mountRoot "DriverRescue"
    New-Item -ItemType Directory -Force -Path $toolsPath, $rescuePath | Out-Null

    Copy-Item -Force -Path "$PSScriptRoot\DriverRestore.ps1" -Destination (Join-Path $toolsPath "DriverRestore.ps1")
    Copy-Item -Force -Path "$PSScriptRoot\Generate-RescueReport.ps1" -Destination (Join-Path $toolsPath "Generate-RescueReport.ps1")
    Copy-Item -Force -Path "$PSScriptRoot\DriverRestore.cmd" -Destination (Join-Path $mountRoot "DriverRestore.cmd")
    Copy-Item -Force -Path "$PSScriptRoot\DriverRescueMenu.cmd" -Destination (Join-Path $mountRoot "DriverRescueMenu.cmd")
    Copy-Item -Force -Path "$PSScriptRoot\Unlock-BitLockerVolume.cmd" -Destination (Join-Path $mountRoot "Unlock-BitLockerVolume.cmd")

    if (Test-Path $DriverSource) {
        $isoDriverPath = Join-Path $rescuePath "Drivers"
        New-Item -ItemType Directory -Force -Path $isoDriverPath | Out-Null
        Copy-Item -Recurse -Force -Path (Join-Path $DriverSource "*") -Destination $isoDriverPath -ErrorAction SilentlyContinue
        Write-Host "Bundled drivers from $DriverSource"
    } else {
        Write-Host "No local drivers folder found. External driver media can still be used."
    }

    $startnet = Join-Path $mountRoot "Windows\System32\startnet.cmd"
    @"
wpeinit
echo.
echo WinPE Driver Rescue is ready.
echo Run DriverRescueMenu.cmd for restore, scan, BitLocker, and report tools.
echo.
cd /d X:\
call X:\DriverRescueMenu.cmd
"@ | Set-Content -Encoding ASCII -Path $startnet

    Invoke-Native -FilePath "dism.exe" -Arguments @("/Unmount-Image", "/MountDir:$mountRoot", "/Commit")
} catch {
    Write-Warning "Build failed. Discarding mounted image."
    dism /Unmount-Image /MountDir:$mountRoot /Discard | Out-Null
    throw
}

Invoke-Native -FilePath $adk.MakeWinPeMedia -Arguments @("/ISO", $workRoot, $isoPath)

Write-Host ""
Write-Host "Created ISO: $isoPath"
Write-Host "Build log:   $BuildLogPath"
Write-Host "Write it to USB with Rufus, Ventoy, or another trusted ISO-to-USB tool."
} finally {
    if ($transcriptStarted) {
        Stop-Transcript | Out-Null
    }
}
