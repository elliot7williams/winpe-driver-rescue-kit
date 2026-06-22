# Testing

Use this checklist before trusting the ISO for a real repair.

## Build Test

Run on a Windows 10 or Windows 11 machine with the Windows ADK and WinPE add-on
installed.

```powershell
.\Build-DriverRescueIso.ps1 -Force
```

Expected result:

- `out\DriverRescue.iso` is created.
- The build output shows WinPE PowerShell optional components being added.
- No mounted image is left behind in `out\mount`.

If a build fails while the image is mounted, clean it up:

```cmd
dism /Unmount-Image /MountDir:out\mount /Discard
```

## VM Smoke Test

1. Create a temporary Windows VM.
2. Attach `out\DriverRescue.iso` as boot media.
3. Attach a second virtual disk or USB pass-through containing a `drivers`
   folder with at least one valid `.inf` package.
4. Boot into WinPE.
5. Run:

```cmd
DriverRestore.cmd
```

Expected result:

- The tool finds the installed Windows volume.
- The tool finds `.inf` files from `X:\DriverRescue\Drivers` or external media.
- The tool asks for confirmation before installing.

## Dry-Run Test

Run this inside WinPE:

```powershell
powershell -ExecutionPolicy Bypass -File X:\Tools\DriverRestore.ps1 -DryRun
```

Expected result:

- The script lists driver sources.
- The script lists every `.inf` file that would be installed.
- No DISM `/Add-Driver` command is executed.

## External Driver Media Test

Prepare a USB drive like this:

```text
USB-DRIVERS\
  drivers\
    network\
    chipset\
    storage\
```

Expected result:

- The restore script scans the external `drivers` folder.
- It skips obvious installed Windows/system folders.
- It writes `DriverRescue-Restore.log` to the repaired Windows volume after a
  real restore.

## BitLocker Test

Use only on a test machine where you have the recovery key.

1. Boot into WinPE.
2. Run:

```cmd
Unlock-BitLockerVolume.cmd C:
```

3. Enter the 48-digit recovery key.
4. Confirm the Windows volume can be read.
5. Run `DriverRestore.cmd`.

Expected result:

- `manage-bde` unlocks the volume.
- The restore script can see the Windows installation.

After Windows boots successfully, re-enable protectors:

```cmd
manage-bde -protectors -enable C:
```

## Real Hardware Checklist

Before using on a real broken PC, confirm:

- The ISO boots on the target firmware mode, UEFI or legacy BIOS.
- The internal Windows disk is visible in WinPE.
- If the disk is not visible, storage/NVMe/RAID drivers are bundled into the ISO.
- The external driver USB is visible in WinPE.
- BitLocker recovery keys are available if the system is encrypted.
- Vendor driver packages include `.inf` files, not only `.exe` installers.

