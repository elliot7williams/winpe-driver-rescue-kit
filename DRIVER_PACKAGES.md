# Driver Packages

This toolkit works best with extracted driver packages that contain `.inf`
files.

## What To Put On The USB Drive

Use a layout like this:

```text
USB-DRIVERS\
  drivers\
    network\
    storage\
    chipset\
    graphics\
```

The restore script scans folders named `drivers`, `Drivers`, `driver`, or
`Driver` on attached drives.

## Required Files

A usable driver package usually contains files like:

```text
example.inf
example.cat
example.sys
```

The `.inf` file describes the driver. The `.cat` file is the catalog signature.
The `.sys`, `.dll`, or related files contain the driver binaries.

Keep each driver package folder intact. Do not copy only the `.inf` file.

## Export Drivers From A Working PC

On a similar working Windows PC, run:

```powershell
.\Export-InstalledDrivers.ps1 -Destination E:\drivers
```

This exports installed third-party drivers into a folder that can be used with
the rescue ISO.

## Vendor Driver Packs

Many business PC vendors provide driver packs that are easier to use than
individual installers.

Useful search terms:

- Dell command deploy driver packs
- HP client management driver packs
- Lenovo SCCM driver packages
- Intel Ethernet adapter driver pack
- Intel RST F6 driver
- AMD RAID driver package
- NVIDIA enterprise driver inf

Download drivers only from the device vendor, component vendor, Microsoft
Update Catalog, or another trusted source.

## Vendor EXE Installers

Many vendor downloads are `.exe` installers. DISM usually cannot inject those
directly into offline Windows.

Look for an extract option such as:

```cmd
setup.exe /extract
driver.exe /s /e
driver.exe /extract
```

Exact switches vary by vendor. Some installers can also be extracted with
archive tools, but only use files from trusted sources.

## Storage And Network Drivers

Prioritize these categories for rescue media:

- Storage, NVMe, RAID, Intel RST, AMD RAID
- Chipset
- Ethernet
- Wi-Fi
- USB controller

Storage drivers are especially important because WinPE must see the internal
disk before it can repair the installed Windows volume.

## Architecture And Windows Version

Match the driver package to the target Windows installation:

- Use 64-bit drivers for 64-bit Windows.
- Use Windows 10 or Windows 11 drivers as appropriate.
- Avoid mixing ARM64 and x64 driver packages.
