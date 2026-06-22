# WinPE Driver Rescue Kit

This project builds a bootable Windows PE ISO that can restore missing or broken
Windows drivers from external media.

Use case: a Windows machine boots poorly, has no network, no storage driver, no
touchpad, or has broken device drivers. Boot this rescue ISO, plug in a USB drive
containing driver folders, and run the included restore tool to inject those
drivers back into the installed Windows system.

## What This Creates

- A bootable WinPE ISO named `DriverRescue.iso`
- A rescue script available inside WinPE at `X:\Tools\DriverRestore.ps1`
- A desktop command shortcut inside WinPE named `DriverRestore.cmd`
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

The ISO will be created at:

```text
.\out\DriverRescue.iso
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
3. In WinPE, run:

```cmd
DriverRestore.cmd
```

Or run the PowerShell script directly:

```powershell
powershell -ExecutionPolicy Bypass -File X:\Tools\DriverRestore.ps1
```

The tool will:

- Find installed Windows volumes
- Ask which Windows installation to repair
- Scan bundled and external driver folders
- Install matching `.inf` drivers with DISM
- Write a log file to the repaired Windows drive

## Exporting Drivers From A Working PC

On a healthy Windows machine, you can export installed third-party drivers:

```powershell
.\Export-InstalledDrivers.ps1 -Destination E:\drivers
```

Then use that USB drive with the rescue ISO.

## Important Notes

- This kit restores driver packages. It does not repair Windows system files,
  reset passwords, bypass BitLocker, or recover encrypted data.
- If the target Windows drive is BitLocker-protected, unlock it first from WinPE
  before running the restore script.
- Secure Boot compatibility depends on how the ISO is written to USB and the
  target system firmware settings.
- For storage controller problems, include storage/NVMe/RAID drivers in the ISO
  itself so WinPE can see the internal disk.

