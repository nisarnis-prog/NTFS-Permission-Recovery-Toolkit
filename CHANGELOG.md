# Changelog

## 1.0.0

- Retained the original 36-folder layout and four batch boundaries.
- Fixed PowerShell string interpolation and corrected example filenames.
- Restricted recovery and logging paths to fixed local NTFS volumes. Added linked-path checks and required logs outside the recovery root.
- Made the saved manifest order-sensitive and exclusive on creation. Added unique run identifiers to logs and reports.
- Changed recursive ownership to skip directories on the native access prompt. Used the local Administrators SID for the grant and the documented inheritance switch.
- Added a user guide, safety notes, examples, and MIT licensing.
