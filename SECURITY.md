# Security Policy

## Supported Versions

Security updates apply to the latest commit on the `main` branch unless a
release branch exists.

## What This Tool Does

WinPE Driver Rescue Kit helps restore driver packages into an existing Windows
installation from WinPE.

It is intended for legitimate repair cases where the user owns or administers
the computer.

## What This Tool Does Not Do

This project does not:

- Bypass Windows passwords
- Bypass BitLocker encryption
- Recover encrypted data
- Remove malware
- Disable Windows security controls
- Circumvent device ownership or access controls

If a Windows volume is protected by BitLocker, the user must provide a valid
BitLocker recovery key.

## Reporting A Security Issue

Please open a private security advisory on GitHub if available, or open an
issue with minimal details and request a private follow-up.

Do not post recovery keys, serial numbers, service tags, personal data, logs
with secrets, or screenshots containing sensitive information in public issues.
