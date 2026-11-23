# NTFS Permission Recovery Toolkit

Version 1.0.0 release candidate • Nisar Muhammad

## 1. Decide whether the toolkit fits

Use this workflow for ownership and NTFS permission repair on a local data tree with exactly 36 immediate subfolders. It can help when Administrator ownership or folder inheritance needs to be restored as part of an approved access plan. It does not recover deleted files, repair storage hardware, restore encrypted data, or guarantee recovery of corrupted files.

## 2. Download and prepare

1. Download the toolkit ZIP and select **Extract All** in File Explorer. Keep its folder structure intact. For a script-only download, save the raw PowerShell file and put it in a `scripts` subfolder to use the commands below.
2. Open **Windows PowerShell** and run `$PSVersionTable.PSVersion` to check for version 5.1.
3. Navigate to the extracted toolkit folder. Create an independent disposable copy on a fixed local NTFS volume. The commands use `C:\RecoveryTest\SampleFolder` as the example root and `C:\RecoveryTest\Logs` for private logs. Replace both paths as needed.

### Safety checklist

- Count the 36 immediate subfolders and verify you have permission to administer the test copy.
- Verify a full backup by testing recovery. Record baseline ownership and ACLs and review the parent folder's grants and explicit denies.
- Keep the tree static throughout preview and Apply. Use a private log directory outside the target and avoid linked trees, system folders, active shares, and production data.

## 3. Preview one batch

```powershell
.\scripts\NTFS_Recovery_Public_V1.ps1 -Root 'C:\RecoveryTest\SampleFolder' -Batch 1 -LogRoot 'C:\RecoveryTest\Logs'
```

1. Open the new batch log in the log directory. Check the root and each `SELECTED` entry.
2. Batch 1 uses positions 1–10, batch 2 uses 11–20, batch 3 uses 21–30, and batch 4 uses 31–36. Positions refer to the script's name-sorted list.
3. Keep the manifest that preview creates. Apply checks its exact order against the current list. If selection differs from your plan, stop and investigate. Preview writes logs and a manifest but makes no owner or ACL changes.

## 4. Apply the reviewed batch

1. Open Windows PowerShell as Administrator and navigate to the same extracted folder.
2. Reuse the same root, log directory and batch. Use `-BackupVerified` only after verifying a recoverable backup.

```powershell
.\scripts\NTFS_Recovery_Public_V1.ps1 -Root 'C:\RecoveryTest\SampleFolder' -Batch 1 -LogRoot 'C:\RecoveryTest\Logs' -Apply -BackupVerified
```

3. Type `APPLY BATCH 1` at the prompt. For another batch, use the corresponding number in both the command and confirmation.
4. Read the run log and CSV and confirm each expected snapshot exists. Inspect ownership and permissions in **Properties > Security > Advanced**, then test access as the intended user. Stop on unexpected results before running another batch.

## 5. What changes

For each selected folder, the toolkit captures a DACL snapshot with Windows ICACLS, recursively assigns ownership to the local Administrators group, adds its Full Control grant, and enables inheritance. It reports native output and exit codes. Existing explicit denies can still affect access. A failure may leave partial changes, and the DACL snapshot does not substitute for a full backup or ownership inventory.

## 6. If a check fails

- **Wrong folder count or manifest mismatch.** Verify the root and investigate changes. Use a new log directory for preview only if the layout was intentionally revised.
- **Linked item or cannot enumerate.** Inspect the selected tree. Use an independent, readable copy.
- **Snapshot or command error.** Review the log and CSV. Check what changed before retrying. Use your tested restore plan when needed.
- **Access still denied.** Check the parent ACL, explicit denies, encryption, and the effective access of the intended user.

## 7. License and responsibility

The MIT License allows free personal and commercial use, modification, and redistribution when the copyright and license notice are retained. The toolkit is provided as is, without warranty. You are responsible for authorization, backups, testing, and deployment. Logs, manifests, snapshots and reports may expose sensitive paths and ACL entries. Keep them private.
