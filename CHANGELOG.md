# Changelog

All notable changes to this project are documented here.

## Unreleased

Added:

- `ROADMAP.md` with near-term, medium-term, and longer-term project direction.

Changed:

- Driver restore and report logs now fall back to `X:\DriverRescueLogs` if the
  target Windows drive cannot be used for logs.
- Driver restore now lists failed `.inf` packages at the end and exits with a
  failure code if any package fails.
- BitLocker helper now reports when `manage-bde.exe` is unavailable.

## v0.1.1 - 2026-06-22

Added:

- Build transcript logging to `out\Build.log` by default.
- `EXAMPLES.md` with sample menu output, dry-run output, restore log snippets,
  and rescue report snippets.

## v0.1.0 - 2026-06-22

Initial public release.

Added:

- WinPE ISO builder using the Windows ADK and WinPE add-on.
- Driver restore script for injecting `.inf` packages into offline Windows.
- Interactive WinPE rescue menu.
- Dry-run driver scanning.
- Timestamped restore and scan logs.
- Rescue report generation.
- BitLocker unlock helper.
- Installed-driver export helper for working Windows systems.
- Testing checklist, troubleshooting guide, limitations guide, and driver
  package guide.
- GitHub issue templates, security policy, contribution guide, release checklist,
  MIT License, and PowerShell lint workflow.
