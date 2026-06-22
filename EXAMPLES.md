# Examples

These examples show what normal output can look like. Paths, drive letters,
driver names, and device details vary by machine.

## Boot Menu

When the ISO boots, the rescue menu opens automatically:

```text
========================================
       WinPE Driver Rescue Kit
========================================

 1. Restore drivers
 2. Dry-run driver scan
 3. Unlock BitLocker volume
 4. Generate rescue report
 5. Open command prompt
 6. Reboot
 7. Exit menu

Choose an option:
```

## Dry-Run Driver Scan

Dry-run mode scans driver sources and writes `DriverScan.txt` without installing
anything:

```text
=== WinPE Driver Rescue ===

=== Driver sources ===
X:\DriverRescue\Drivers
E:\drivers

Scanning X:\DriverRescue\Drivers
Scanning E:\drivers

=== Restore target ===
Windows path: C:\Windows
Driver count: 18
Log folder:   C:\DriverRescueLogs\20260622-143000
Scan log:     C:\DriverRescueLogs\20260622-143000\DriverScan.txt

=== Dry run ===
No drivers were installed.
The following .inf files would be added:
E:\drivers\network\e1d.inf
E:\drivers\chipset\iaLPSS2_GPIO2.inf
```

## DriverScan.txt

```text
WinPE Driver Rescue scan
Timestamp: 2026-06-22T14:30:00
Windows path: C:\Windows

Driver sources:
X:\DriverRescue\Drivers
E:\drivers

INF files:
E:\drivers\network\e1d.inf
E:\drivers\storage\iaStorVD.inf
```

## Restore.log

```text
WinPE Driver Rescue restore
Timestamp: 2026-06-22T14:31:12
Windows path: C:\Windows
Driver count: 18

Deployment Image Servicing and Management tool
Version: 10.0.26100.1

Image Version: 10.0.26100.1

Found 1 driver package(s) to install.
Installing 1 of 1 - E:\drivers\network\e1d.inf: The driver package was
successfully installed.
The operation completed successfully.
```

## SystemReport.txt

```text
WinPE Driver Rescue report
Timestamp: 2026-06-22T14:32:04
Computer name: MININT-123456
Report path: C:\DriverRescueLogs\20260622-143204\SystemReport.txt

=== Windows installations ===

Drive WindowsPath
----- -----------
C:\   C:\Windows

=== Driver source folders ===
X:\DriverRescue\Drivers
E:\drivers

=== Driver INF count ===
X:\DriverRescue\Drivers : 4
E:\drivers : 18
```

## Build.log

The ISO builder writes a transcript to `out\Build.log`:

```text
Build log: .\out\Build.log
Running: copype.cmd amd64 .\out\work
Running: dism.exe /Mount-Image /ImageFile:.\out\work\media\sources\boot.wim /Index:1 /MountDir:.\out\mount
Running: dism.exe /Image:.\out\mount /Add-Package /PackagePath:WinPE-PowerShell.cab
Created ISO: .\out\DriverRescue.iso
Build log:   .\out\Build.log
```
