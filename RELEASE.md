# Release Checklist

Use this checklist when preparing a public release.

## Before Tagging

1. Build the ISO on a clean Windows machine with the Windows ADK and WinPE
   add-on installed.
2. Run the build test in `TESTING.md`.
3. Run the VM smoke test in `TESTING.md`.
4. Confirm the menu opens automatically.
5. Confirm dry-run mode writes `DriverScan.txt`.
6. Confirm restore mode asks for confirmation before installing drivers.
7. Confirm `Generate-RescueReport.ps1` writes `SystemReport.txt`.
8. Confirm BitLocker instructions are still accurate.
9. Review README examples for the current command names.

## Version Tag

Use a semantic version tag:

```powershell
git tag v0.1.0
git push origin v0.1.0
```

## Release Notes

Include:

- Main changes
- Known limitations
- Tested Windows and ADK versions
- Whether the ISO was tested in a VM or on real hardware
- Any required manual steps

## Do Not Upload

Do not upload Microsoft ADK files, WinPE base images, generated boot media, or
vendor driver packages unless you have confirmed that redistribution is allowed.

It is safest to publish the scripts and let users build their own ISO locally
with Microsoft's ADK and WinPE add-on.
