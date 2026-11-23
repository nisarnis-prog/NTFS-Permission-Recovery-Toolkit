# Troubleshooting

| Symptom | Action |
| --- | --- |
| Folder count differs from 36 | Check the immediate subfolder count and root. Preserve the intended grouping. |
| Manifest missing | Run preview with the same root and log directory before Apply. |
| Manifest differs | Investigate the layout change. For an intentionally revised disposable copy, preview with a new private log directory. |
| Linked item refused | Check the selected path for junctions, symlinks, mount points, and hard links. Use a fresh independent copy. |
| Apply blocked | Verify restore capability, run Windows PowerShell as Administrator and repeat the reviewed command with both Apply switches. |
| Snapshot or native step fails | Stop and read the log and CSV. A folder may have changed partially. Verify ownership and DACLs before retrying or restoring. |
| Access remains denied | Review explicit denies, parent permissions, encryption, and the intended user's effective access. |
| Script execution is blocked | Consult your Windows execution policy and administrator before making changes. |
