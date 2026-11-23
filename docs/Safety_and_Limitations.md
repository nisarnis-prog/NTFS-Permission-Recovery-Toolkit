# Safety and limitations

- Use a fixed local NTFS volume and a dedicated data root with 36 immediate subfolders. Drive roots, network paths, and detected reparse points or hard links in selected trees are refused. Avoid Windows, application, profile and active shared folders.
- Keep the target and log directories under exclusive administrative control. Preflight checks are snapshots. Concurrent renames, link creation, or other changes can invalidate them. Use a dedicated, access-restricted log directory outside the target.
- Preview writes a manifest and log, and requires read access to the selected trees. Apply needs administrator elevation, an existing matching manifest, the operator's backup assertion, and typed confirmation.
- The DACL snapshot does not capture a full backup or reliably restore ownership. Native recursion can partially succeed. Inheritance can broaden access, and explicit Deny rules can still block users. Verify effective access for each intended account.
- The native ownership command uses English `/D N` syntax. Other Windows display languages and Windows Server builds require independent validation.
- Logs, CSVs, snapshots and manifests can contain paths, names and ACL information. Keep them private and redact them before sharing excerpts.
- This toolkit addresses permission and ownership issues. Deleted files, damaged disks, corrupted files, encryption recovery and share permissions are outside its scope.
