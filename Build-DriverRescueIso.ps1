#Requires -RunAsAdministrator
[CmdletBinding()]
param(
    [string]$Architecture = "amd64",
    [string]$Locale = "en-us",
    [string]$OutputDirectory = "$PSScriptRoot\out",
    [string]$IsoName = "DriverRescue.iso",
    [string]$DriverSource = "$PSScriptRoot\drivers",
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

New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null

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
    Copy-Item -Force -Path "$PSScriptRoot\DriverRestore.cmd" -Destination (Join-Path $mountRoot "DriverRestore.cmd")

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
echo Run DriverRestore.cmd to restore drivers to an installed Windows volume.
echo.
cd /d X:\
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
Write-Host "Write it to USB with Rufus, Ventoy, or another trusted ISO-to-USB tool."
