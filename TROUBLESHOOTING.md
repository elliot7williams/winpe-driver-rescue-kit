# Troubleshooting

## Build Script Cannot Find The ADK

Install both:

- Windows Assessment and Deployment Kit
- Windows PE add-on for the ADK

Then run PowerShell as Administrator and try again:

```powershell
.\Build-DriverRescueIso.ps1 -Force
```

## Output Already Exists

If the build output already exists, use:

```powershell
.\Build-DriverRescueIso.ps1 -Force
```

If a prior build left a mounted image behind, discard it:

```cmd
dism /Unmount-Image /MountDir:out\mount /Discard
```

## ISO Boots But PowerShell Does Not Work

The build script adds the WinPE PowerShell optional components. Rebuild the ISO
and check the output for these packages:

- `WinPE-WMI`
- `WinPE-NetFX`
- `WinPE-Scripting`
- `WinPE-PowerShell`
- `WinPE-StorageWMI`
- `WinPE-DismCmdlets`

If those packages are missing, reinstall the WinPE add-on for the ADK.

## WinPE Cannot See The Internal Disk

This usually means WinPE is missing a storage controller driver.

Try:

1. Download storage, NVMe, RAID, Intel RST, or AMD RAID drivers for the target
   device.
2. Put the extracted driver package under `drivers\`.
3. Rebuild the ISO.
4. Boot the target device again.

Firmware settings can also affect disk visibility. Check RAID/AHCI/VMD settings
carefully before changing them, because changing storage mode can stop Windows
from booting.

## Windows Volume Is Missing

Possible causes:

- BitLocker is locked.
- WinPE cannot see the storage controller.
- The Windows partition has no drive letter.
- The Windows installation is badly damaged.

For BitLocker, run:

```cmd
Unlock-BitLockerVolume.cmd C:
```

If the volume has no drive letter, use DiskPart carefully:

```cmd
diskpart
list volume
select volume NUMBER
assign letter=C
exit
```

## No Driver Folders Were Found

The restore script scans attached drives for folders named:

- `drivers`
- `Drivers`
- `driver`
- `Driver`

Place extracted driver packages under one of those folders, then run the dry-run
scan again.

## No INF Files Were Found

The driver package may still be inside a vendor installer.

Extract the installer or download a driver pack that contains `.inf`, `.cat`,
and driver binary files. See `DRIVER_PACKAGES.md`.

## DISM Add-Driver Fails

Check `Restore.log` for the failing driver path and DISM error.

Common causes:

- Wrong architecture
- Wrong Windows version
- Missing files from the driver package folder
- Unsigned or blocked driver package
- Corrupt download

Try a newer vendor package, a model-specific package, or a driver exported from
a similar working PC.

## Network Still Does Not Work After Restore

Confirm the network driver package matches the exact hardware ID. If possible,
export drivers from the same model of working PC:

```powershell
.\Export-InstalledDrivers.ps1 -Destination E:\drivers
```

Then boot the rescue ISO and restore from that USB drive.

## Logs And Reports

Look under the repaired Windows volume:

```text
C:\DriverRescueLogs\
```

If the repaired Windows volume is not writable, the scripts try to write logs
under the WinPE RAM drive instead:

```text
X:\DriverRescueLogs\
```

Useful files:

- `DriverScan.txt`
- `Restore.log`
- `SystemReport.txt`

Share only sanitized logs. Remove recovery keys, serial numbers, service tags,
usernames, hostnames, and other sensitive information before posting publicly.
