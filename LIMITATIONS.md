# Limitations

WinPE Driver Rescue Kit is a driver repair tool, not a full Windows repair or
data recovery environment.

## It Does Not Reinstall Windows

The toolkit injects driver packages into an existing Windows installation. It
does not reinstall Windows, reset Windows, repair system files, or replace a
damaged registry.

If Windows system files are corrupted, use Windows recovery tools such as SFC,
DISM repair, System Restore, startup repair, or a reinstall workflow.

## It Requires Valid Driver Packages

The restore script installs `.inf` driver packages with DISM.

It cannot directly install most vendor `.exe` installers. Extract those
installers first, or download enterprise/driver-pack versions that contain
`.inf`, `.cat`, and `.sys` files.

## BitLocker Requires A Recovery Key

This toolkit does not bypass BitLocker. If the Windows volume is encrypted, the
user must unlock it with a valid BitLocker recovery key before drivers can be
restored.

## Storage Drivers May Need To Be Bundled

If WinPE cannot see the internal Windows disk, the restore script cannot repair
that installation.

For storage, NVMe, RAID, Intel RST, AMD RAID, or vendor storage-controller
problems, bundle those drivers into the ISO ahead of time under `drivers\`.

## Hardware Matching Still Matters

DISM can add driver packages to the offline Windows driver store, but Windows
still chooses drivers based on hardware IDs, signatures, architecture, and
compatibility.

Use drivers that match:

- Device model
- Windows version
- CPU architecture
- Storage or network controller hardware

## Secure Boot And Firmware Behavior Vary

Boot behavior depends on the target device firmware, Secure Boot settings, and
how the ISO was written to USB. Test the ISO on similar hardware before relying
on it during an emergency.

## WinPE Is A Limited Environment

WinPE does not include every Windows component. Networking, PowerShell modules,
device detection, and UI behavior can differ from full Windows.

The build script adds the WinPE optional components needed by this toolkit, but
some vendor tools may still not run inside WinPE.

## No Malware Removal Or Password Recovery

The project intentionally does not include malware removal, password reset,
credential recovery, ownership bypass, or encryption bypass behavior.
