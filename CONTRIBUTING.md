# Contributing

Thanks for helping improve WinPE Driver Rescue Kit.

## Development Expectations

- Keep scripts compatible with Windows PowerShell in WinPE.
- Prefer clear batch and PowerShell commands over hidden automation.
- Do not add password bypass, BitLocker bypass, malware removal, or data recovery
  behavior.
- Keep logs plain text and easy to collect from a repaired Windows volume.
- Avoid bundling vendor drivers, Microsoft ADK files, or generated WinPE images
  in the repository.

## Testing

Before opening a pull request, run the relevant checks in `TESTING.md`.

At minimum, confirm:

- The ISO builds on a Windows machine with the ADK and WinPE add-on.
- `DriverRescueMenu.cmd` opens in WinPE.
- Dry-run mode creates `DriverScan.txt` without installing drivers.
- Real restore mode asks for confirmation before calling DISM.
- `Generate-RescueReport.ps1` creates `SystemReport.txt`.

## Style

- Use ASCII text unless a file already requires otherwise.
- Keep PowerShell parameters named and discoverable.
- Use timestamped log folders for new output.
- Keep README instructions short enough to follow during a repair.
