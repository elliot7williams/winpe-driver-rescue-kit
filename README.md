# WinPE Driver Rescue Kit

[![PowerShell lint](https://github.com/elliot7williams/winpe-driver-rescue-kit/actions/workflows/powershell-lint.yml/badge.svg)](https://github.com/elliot7williams/winpe-driver-rescue-kit/actions/workflows/powershell-lint.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

This project builds a bootable Windows PE ISO that can restore missing or broken
Windows drivers from external media.

Use case: a Windows machine boots poorly, has no network, no storage driver, no
touchpad, or has broken device drivers. Boot this rescue ISO, plug in a USB drive
containing driver folders, and run the included restore tool to inject those
drivers back into the installed Windows system.

## What This Creates

- A bootable WinPE ISO named `DriverRescue.iso`
- An interactive WinPE menu named `DriverRescueMenu.cmd`
- A rescue script available inside WinPE at `X:\Tools\DriverRestore.ps1`
- A desktop command shortcut inside WinPE named `DriverRestore.cmd`
- A BitLocker unlock helper inside WinPE named `Unlock-BitLockerVolume.cmd`
- A rescue report script available inside WinPE at `X:\Tools\Generate-RescueReport.ps1`
- Optional automatic driver folder bundled into the ISO
- Optional automatic scan of external USB media for `.inf` drivers

## Requirements

Run the builder on a Windows PC with:

- Windows 10 or Windows 11
- Administrator PowerShell
- Windows Assessment and Deployment Kit
- Windows PE add-on for the ADK

Download the ADK and WinPE add-on from Microsoft:

https://learn.microsoft.com/windows-hardware/get-started/adk-install

## Quick Start

1. Install the Windows ADK and Windows PE add-on.
2. Open PowerShell as Administrator.
3. Go to this folder.
4. Build the ISO:

```powershell
.\Build-DriverRescueIso.ps1
```

For full script help:

```powershell
Get-Help .\Build-DriverRescueIso.ps1 -Full
```

The ISO will be created at:

```text
.\out\DriverRescue.iso
```

The build transcript is written to:

```text
.\out\Build.log
```

## Bundling Drivers Into The ISO

Place driver packages under `drivers\`. Driver packages must include `.inf`
files.

Example:

```text
drivers\
  Dell-Latitude-7420\
    network\
      e1d.inf
    chipset\
      iaLPSS2_GPIO2.inf
```

Then run:

```powershell
.\Build-DriverRescueIso.ps1
```

Bundled drivers will appear inside WinPE at:

```text
X:\DriverRescue\Drivers
```

## Using External Driver Media

You can also keep drivers on a separate USB drive. The restore script scans all
attached drives for `.inf` files, skipping obvious Windows/system folders.

A simple external USB layout works fine:

```text
USB-DRIVERS\
  drivers\
    network\
    storage\
    chipset\
```

## Boot And Restore

1. Boot the broken PC from `DriverRescue.iso`.
2. Attach the USB drive that contains drivers, if you are using one.
3. In WinPE, the menu opens automatically. If needed, run:

```cmd
DriverRescueMenu.cmd
```

The menu includes:

- Restore drivers
- Dry-run driver scan
- Unlock BitLocker volume
- Generate rescue report
- Open command prompt
- Reboot

You can also run the restore shortcut directly:

```cmd
DriverRestore.cmd
```

Or run the PowerShell script directly:

```powershell
powershell -ExecutionPolicy Bypass -File X:\Tools\DriverRestore.ps1
```

To preview what would be installed without changing the Windows installation:

```powershell
powershell -ExecutionPolicy Bypass -File X:\Tools\DriverRestore.ps1 -DryRun
```

The tool will:

- Find installed Windows volumes
- Ask which Windows installation to repair
- Scan bundled and external driver folders
- Install matching `.inf` drivers with DISM
- Write timestamped logs to `DriverRescueLogs` on the repaired Windows drive

## Logs And Reports

Restore runs and dry-run scans create a timestamped folder on the repaired
Windows volume:

```text
C:\DriverRescueLogs\
  20260622-143000\
    DriverScan.txt
    Restore.log
```

To generate a hardware and environment report from WinPE:

```powershell
powershell -ExecutionPolicy Bypass -File X:\Tools\Generate-RescueReport.ps1
```

The report includes detected Windows installs, file-system drives, driver
source folders, `.inf` counts, DiskPart volume output, WinPE driver output,
network configuration, and BitLocker status.

## Exporting Drivers From A Working PC

On a healthy Windows machine, you can export installed third-party drivers:

```powershell
.\Export-InstalledDrivers.ps1 -Destination E:\drivers
```

Then use that USB drive with the rescue ISO.

## BitLocker

If the Windows drive is encrypted with BitLocker, unlock it before restoring
drivers. From WinPE, run:

```cmd
Unlock-BitLockerVolume.cmd C:
```

Then enter the 48-digit recovery key when prompted.

You can also use `manage-bde` directly:

```cmd
manage-bde -unlock C: -RecoveryPassword YOUR-48-DIGIT-KEY
manage-bde -protectors -disable C:
```

Re-enable BitLocker protectors after Windows boots normally again:

```cmd
manage-bde -protectors -enable C:
```

## Important Notes

- This kit restores driver packages. It does not repair Windows system files,
  reset passwords, bypass BitLocker, or recover encrypted data.
- If the target Windows drive is BitLocker-protected, unlock it first from WinPE
  before running the restore script.
- Secure Boot compatibility depends on how the ISO is written to USB and the
  target system firmware settings.
- For storage controller problems, include storage/NVMe/RAID drivers in the ISO
  itself so WinPE can see the internal disk.
- Test the ISO in a VM before relying on it during a repair. See `TESTING.md`.

## Project Docs

- `TESTING.md` covers build, VM, dry-run, BitLocker, report, and hardware checks.
- `EXAMPLES.md` shows sample menu, dry-run, restore log, and report output.
- `LIMITATIONS.md` explains what the toolkit can and cannot repair.
- `DRIVER_PACKAGES.md` explains how to prepare usable `.inf` driver packages.
- `TROUBLESHOOTING.md` covers common ADK, WinPE, DISM, disk, and driver issues.
- `RELEASE.md` covers release packaging and redistribution warnings.
- `CONTRIBUTING.md` covers contribution expectations and script style.
- `SECURITY.md` explains the project security boundaries.
- `CHANGELOG.md` tracks notable project changes.
- This project is licensed under the MIT License. See `LICENSE`.
