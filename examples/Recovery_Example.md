# Apply batch 1

After reviewing the preview and testing restoration, open Windows PowerShell as Administrator in the extracted toolkit folder.

```powershell
.\scripts\NTFS_Recovery_Public_V1.ps1 -Root 'C:\RecoveryTest\SampleFolder' -Batch 1 -LogRoot 'C:\RecoveryTest\Logs' -Apply -BackupVerified
```

Type `APPLY BATCH 1`. Review every step in the CSV and log, compare the ACL snapshots, and verify effective access.
