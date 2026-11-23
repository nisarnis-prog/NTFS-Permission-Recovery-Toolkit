# NTFS Permission Recovery Toolkit - Nisar Muhammad
# Windows PowerShell 5.1. Run elevated on a TEST COPY first.
# PREVIEW is the default. Applying changes is potentially disruptive.
# This is a case-specific recovery pattern, not a general-purpose ACL reset.
# Example preview:
#   .\NTFS_Recovery_Public_V1.ps1 -Root 'C:\RecoveryTest\SampleFolder' -Batch 1
# Example apply (only after verifying backup, ACLs, and preview):
#   .\NTFS_Recovery_Public_V1.ps1 -Root 'C:\RecoveryTest\SampleFolder' -Batch 1 -Apply -BackupVerified
#Requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$Root,
    [ValidateRange(1,4)][int]$Batch = 1,
    [switch]$Apply,
    [switch]$BackupVerified,
    [string]$LogRoot = "$env:ProgramData\NTFS_Permission_Recovery_Toolkit"
)
$ErrorActionPreference = 'Stop'
function Resolve-LocalNtfsPath([string]$Path) {
    if ($Path -notmatch '^[A-Za-z]:\\' -or $Path.Substring(2) -match '[:*?]') {
        throw 'Use an absolute local drive path.'
    }
    $fullPath = [IO.Path]::GetFullPath($Path)
    $drive = [IO.DriveInfo]::new([IO.Path]::GetPathRoot($fullPath))
    if ($drive.DriveType -ne 'Fixed' -or $drive.DriveFormat -ne 'NTFS') {
        throw 'Use a fixed local NTFS drive.'
    }
    if ($fullPath -eq $drive.Name) { throw 'Drive roots are refused.' }
    return $fullPath.TrimEnd('\')
}
$Root = Resolve-LocalNtfsPath $Root
$LogRoot = Resolve-LocalNtfsPath $LogRoot
if ($LogRoot -eq $Root -or $LogRoot.StartsWith("$Root\", [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Place the log directory outside the recovery root.'
}
function Assert-NoReparseAncestor([string]$Path) {
    for ($directory = [IO.DirectoryInfo]::new($Path); $directory; $directory = $directory.Parent) {
        try { $attributes = [IO.File]::GetAttributes($directory.FullName) }
        catch [IO.FileNotFoundException] { continue }
        catch [IO.DirectoryNotFoundException] { continue }
        if ($attributes -band [IO.FileAttributes]::ReparsePoint) {
            throw "Reparse point refused: $($directory.FullName)"
        }
    }
}
Assert-NoReparseAncestor $Root
Assert-NoReparseAncestor $LogRoot
if (-not (Test-Path -LiteralPath $Root -PathType Container)) { throw "Folder not found: $Root" }
if ($Apply -and -not $BackupVerified) { throw 'Apply blocked. Verify a recoverable backup/restore point, then specify -BackupVerified.' }
if ($Apply) {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { throw 'Run PowerShell as Administrator for Apply.' }
}
New-Item -ItemType Directory -Path $LogRoot -Force | Out-Null
# Use a stable per-root manifest name; never silently replace an existing manifest.
$rootHash = [BitConverter]::ToString(([Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($Root.ToUpperInvariant())))).Replace('-','').Substring(0,12)
$manifest = Join-Path $LogRoot ("TopLevel_36_{0}.txt" -f $rootHash)
$stamp = '{0}_{1}' -f (Get-Date -Format 'yyyyMMdd_HHmmss'), [Guid]::NewGuid().ToString('N')
$prefix = Join-Path $LogRoot ("Batch{0}_{1}_{2}" -f $Batch,$rootHash,$stamp)
$log = "$prefix.log"
$report = "$prefix.csv"
$rows = New-Object 'System.Collections.Generic.List[object]'
function Write-Log([string]$Message) {
    $line = '{0} {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'),$Message
    Write-Host $line
    Add-Content -LiteralPath $log -Value $line -Encoding UTF8
}
function Run-External([string]$Exe,[string[]]$Arguments,[string]$Step,[string]$Folder) {
    Write-Log "START $Step : $Folder"
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try { $output = & $Exe @Arguments 2>&1; $exitCode = $LASTEXITCODE }
    finally { $ErrorActionPreference = $previous }
    foreach ($line in $output) { Add-Content -LiteralPath $log -Value ([string]$line) -Encoding UTF8 }
    Write-Log "END $Step : exit code $exitCode"
    $rows.Add([pscustomobject]@{Folder=$Folder;Step=$Step;ExitCode=$exitCode;Status=$(if($exitCode -eq 0){'OK'}else{'FAILED - review log'})})
    return $exitCode
}
$currentNames = @(Get-ChildItem -LiteralPath $Root -Directory -Force | Sort-Object Name | ForEach-Object { $_.Name })
if (-not (Test-Path -LiteralPath $manifest)) {
    if ($Apply) { throw "Manifest missing. Run PREVIEW first: $manifest" }
    if ($currentNames.Count -ne 36) { throw "This case-specific script expects exactly 36 top-level folders; found $($currentNames.Count)." }
    $stream = [IO.File]::Open($manifest, [IO.FileMode]::CreateNew)
    try {
        $writer = [IO.StreamWriter]::new($stream, [Text.Encoding]::UTF8)
        try { foreach ($name in $currentNames) { $writer.WriteLine($name) } }
        finally { $writer.Dispose() }
    }
    finally { $stream.Dispose() }
}
$manifestItem = Get-Item -LiteralPath $manifest -Force
if ($manifestItem.PSIsContainer -or
    ($manifestItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -or
    $manifestItem.LinkType -eq 'HardLink') { throw 'Linked or invalid manifest refused.' }
$allNames = @(Get-Content -LiteralPath $manifest -Encoding UTF8)
if ($allNames.Count -ne 36 -or $currentNames.Count -ne 36 -or ($allNames -join "`n") -cne ($currentNames -join "`n")) {
    throw 'The saved 36-folder manifest differs from the current folder list. Stop and investigate.'
}
$start = ($Batch - 1) * 10
$end = [Math]::Min($start + 9,35)
$selected = @($currentNames[$start..$end])
function Assert-SafeTree([string]$Path) {
    $item = Get-Item -LiteralPath $Path -Force
    if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -or $item.LinkType -eq 'HardLink') {
        throw "Linked item refused: $Path"
    }
    if ($item.PSIsContainer) {
        foreach ($child in Get-ChildItem -LiteralPath $Path -Force) {
            Assert-SafeTree $child.FullName
        }
    }
}
foreach ($name in $selected) { Assert-SafeTree (Join-Path $Root $name) }
Write-Log "Mode: $(if($Apply){'APPLY'}else{'PREVIEW'}) | Batch $Batch | Folder positions $($start+1)-$($end+1)"
Write-Log "Root: $Root | Manifest: $manifest"
foreach ($name in $selected) { Write-Log "SELECTED: $name" }
if (-not $Apply) {
    Write-Log 'PREVIEW ONLY: no ownership or ACL modifications were performed.'
    Write-Log 'Before Apply: confirm restore capability, review inherited/explicit Deny permissions, and capture an ACL backup.'
    return
}
Write-Warning 'RECURSIVE OWNERSHIP/ACL CHANGES MAY ALTER ACCESS TO CONFIDENTIAL DATA.'
Write-Warning 'Enabling inheritance preserves explicit entries, including explicit Deny entries; it may expose inherited permissions.'
Write-Warning 'The script cannot automatically verify backup integrity, business authorization, or effective access.'
$confirmation = Read-Host "Type APPLY BATCH $Batch to confirm"
if ($confirmation -cne "APPLY BATCH $Batch") { Write-Log 'Cancelled by operator'; return }
Assert-NoReparseAncestor $Root
Assert-NoReparseAncestor $LogRoot
foreach ($name in $selected) { Assert-SafeTree (Join-Path $Root $name) }
# Snapshot current ACLs for selected folders before changing them. Keep backups secured.
foreach ($name in $selected) {
    $path = Join-Path $Root $name
    $aclSnapshot = "${prefix}_$([Array]::IndexOf($selected,$name)+1)_ACL_before.txt"
    Write-Log "Backing up ACLs for $name to $aclSnapshot"
    $saveExit = Run-External (Join-Path ([Environment]::SystemDirectory) 'icacls.exe') @($path,'/save',$aclSnapshot,'/T','/C') 'BACKUP_ACL' $name
    if ($saveExit -ne 0) { Write-Log "SKIPPED ${name}: ACL backup failed"; continue }
    $code = Run-External (Join-Path ([Environment]::SystemDirectory) 'takeown.exe') @('/F',$path,'/A','/R','/D','N') 'TAKEOWN' $name
    if ($code -ne 0) { Write-Log "SKIPPED later steps for ${name}: TAKEOWN failed; partial changes possible"; continue }
    $code = Run-External (Join-Path ([Environment]::SystemDirectory) 'icacls.exe') @($path,'/grant','*S-1-5-32-544:(OI)(CI)F','/T','/C') 'GRANT_ADMINS' $name
    if ($code -ne 0) { Write-Log "SKIPPED inheritance for ${name}: grant failed; partial changes possible"; continue }
    $code = Run-External (Join-Path ([Environment]::SystemDirectory) 'icacls.exe') @($path,'/inheritancelevel:e','/T','/C') 'ENABLE_INHERITANCE' $name
    if ($code -ne 0) { Write-Log "Inheritance had failures in $name; review log"; continue }
    Write-Log "COMPLETED $name - manual effective-access and application testing still required"
}
$rows | Export-Csv -LiteralPath $report -NoTypeInformation -Encoding UTF8
Write-Log "Report: $report"
Write-Log 'Inspect all errors, ACL snapshots, effective permissions, and application access before marking a batch successful.'
