# Preview batch 1

From the extracted toolkit folder, use your disposable local NTFS test copy with 36 immediate folders.

```powershell
.\scripts\NTFS_Recovery_Public_V1.ps1 -Root 'C:\RecoveryTest\SampleFolder' -Batch 1 -LogRoot 'C:\RecoveryTest\Logs'
```

Read the log and verify the ten selected folders. Preview leaves ownership and ACLs unchanged.
