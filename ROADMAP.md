# Roadmap

This roadmap lists useful next steps. It is not a promise of dates or scope.

## Near Term

- Run a full Windows ADK build test and record verified ADK, Windows, and WinPE
  versions.
- Boot-test the generated ISO in a VM and document the result in `TESTING.md`.
- Add clearer recovery guidance when no Windows installation is detected.
- Improve handling for locked BitLocker volumes and missing drive letters.
- Expand `EXAMPLES.md` with sanitized output from a real WinPE run.

## Medium Term

- Add optional hardware ID reporting to help match missing devices to drivers.
- Add a mode that ranks likely driver packages before restore.
- Improve storage-driver guidance for Intel VMD/RST, AMD RAID, and NVMe cases.
- Add more compatibility reports from Dell, HP, Lenovo, and custom desktop
  hardware.

## Longer Term

- Explore a small WinPE GUI or richer text UI while keeping command-line scripts
  available.
- Add optional offline Windows health checks that do not modify the installation.
- Add signed release checksums for scripts and documentation bundles.

## Non-Goals

- Password bypass
- BitLocker bypass
- Malware removal
- Data recovery
- Bundling Microsoft WinPE images, ADK files, or vendor driver packages
